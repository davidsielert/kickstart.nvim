local M = {}

local function java_home(version)
  local override = vim.env['JAVA' .. version .. '_HOME']
  if override and vim.fn.executable(override .. '/bin/java') == 1 then
    return override
  end
  if vim.fn.has 'mac' == 1 then
    local result = vim.system({ '/usr/libexec/java_home', '-F', '-v', version == '8' and '1.8' or version }, { text = true }):wait()
    if result.code == 0 then
      return vim.trim(result.stdout)
    end
  end
end

local function major_version(home)
  if not home or vim.fn.filereadable(home .. '/release') == 0 then
    return nil
  end
  local release = table.concat(vim.fn.readfile(home .. '/release'), '\n')
  local version = release:match 'JAVA_VERSION="([^"]+)"' or ''
  return tonumber(version:match '^1%.(%d+)' or version:match '^(%d+)')
end

local runtime_config
function M.runtimes()
  if runtime_config then
    return runtime_config
  end
  local runtimes, latest = {}, nil
  for _, version in ipairs { '8', '11', '17', '21', '25' } do
    local home = java_home(version)
    if home then
      table.insert(runtimes, { name = version == '8' and 'JavaSE-1.8' or 'JavaSE-' .. version, path = home, default = version == '11' })
      if tonumber(version) >= 21 then
        latest = home
      end
    end
  end
  local launch_home = vim.env.JDTLS_JAVA_HOME or latest or vim.env.JAVA_HOME
  if not launch_home then
    local executable = vim.fn.exepath 'java'
    if executable ~= '' then
      launch_home = vim.fs.dirname(vim.fs.dirname(vim.uv.fs_realpath(executable) or executable))
    end
  end
  -- Without a local JDK 21+, nvim-java downloads its own JDK to run the server.
  if (major_version(launch_home) or 0) < 21 then
    launch_home = nil
  elseif not vim.iter(runtimes):any(function(runtime)
    return runtime.path == launch_home
  end) then
    table.insert(runtimes, { name = 'JavaSE-' .. major_version(launch_home), path = launch_home })
  end
  if #runtimes > 0 and not vim.iter(runtimes):any(function(runtime)
    return runtime.default
  end) then
    runtimes[#runtimes].default = true
  end
  runtime_config = { home = launch_home, runtimes = runtimes }
  return runtime_config
end

function M.organize_imports()
  vim.lsp.buf.code_action { context = { only = { 'source.organizeImports' }, diagnostics = {} }, apply = true }
end

local function mappings(buf)
  local java = require 'java'
  local function map(keys, action, desc, mode)
    vim.keymap.set(mode or 'n', '<leader>j' .. keys, action, { buffer = buf, desc = 'Java: ' .. desc })
  end
  -- nvim-java registers its refactor and build APIs once the server attaches, so look them up on each keypress.
  local function refactor(name)
    return function()
      java.refactor[name]()
    end
  end
  map('i', M.organize_imports, 'organize imports')
  map('v', refactor 'extract_variable', 'extract variable', { 'n', 'x' })
  map('V', refactor 'extract_variable_all_occurrence', 'extract variable (all occurrences)', { 'n', 'x' })
  map('c', refactor 'extract_constant', 'extract constant', { 'n', 'x' })
  map('f', refactor 'extract_field', 'extract field', { 'n', 'x' })
  map('m', refactor 'extract_method', 'extract method', 'x')
  map('t', java.test.run_current_method, 'run nearest test')
  map('T', java.test.run_current_class, 'run test class')
  map('A', function()
    require('java-test').run_all_tests()
  end, 'run all tests')
  map('n', java.test.debug_current_method, 'debug nearest test')
  map('N', java.test.debug_current_class, 'debug test class')
  map('w', java.test.view_last_report, 'view last test report')
  map('r', function()
    java.runner.built_in.run_app {}
  end, 'run main class')
  map('x', java.runner.built_in.stop_app, 'stop running main class')
  map('g', java.runner.built_in.toggle_logs, 'toggle run logs')
  map('P', java.profile.ui, 'run profiles (JVM / program arguments)')
  map('a', vim.lsp.buf.code_action, 'code actions / generate code')
  map('k', vim.lsp.buf.signature_help, 'signature help')
  map('I', function()
    vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = buf }, { bufnr = buf })
  end, 'toggle parameter hints')
  map('s', function()
    for _, client in ipairs(vim.lsp.get_clients { bufnr = buf, name = 'jdtls' }) do
      client:notify('java/projectConfigurationUpdate', { uri = vim.uri_from_bufnr(buf) })
    end
  end, 'reload Maven / Gradle project')
  map('S', java.settings.change_runtime, 'change project JDK')
  map('p', function()
    java.build.build_workspace()
  end, 'compile project')
end

function M.setup()
  local runtime = M.runtimes()
  require('java').setup {
    jdk = { auto_install = runtime.home == nil, path = runtime.home },
    spring_boot_tools = { enable = false },
  }
  vim.lsp.config('jdtls', {
    capabilities = require('cmp_nvim_lsp').default_capabilities(),
    settings = {
      java = {
        configuration = { runtimes = runtime.runtimes, updateBuildConfiguration = 'interactive' },
        eclipse = { downloadSources = true },
        maven = { downloadSources = true },
        signatureHelp = { enabled = true },
        contentProvider = { preferred = 'fernflower' },
        completion = {
          favoriteStaticMembers = { 'org.junit.jupiter.api.Assertions.*', 'org.junit.Assert.*', 'org.mockito.Mockito.*' },
          importOrder = { 'java', 'javax', 'org', 'com' },
        },
        sources = { organizeImports = { starThreshold = 9999, staticStarThreshold = 9999 } },
        codeGeneration = { useBlocks = true, hashCodeEquals = { useJava7Objects = true } },
        inlayHints = { parameterNames = { enabled = 'literals' } },
        format = { enabled = true },
      },
    },
  })
  vim.api.nvim_create_autocmd('LspAttach', {
    group = vim.api.nvim_create_augroup('custom-java-attach', { clear = true }),
    callback = function(event)
      local client = vim.lsp.get_client_by_id(event.data.client_id)
      if client and client.name == 'jdtls' then
        mappings(event.buf)
      end
    end,
  })
  vim.lsp.enable 'jdtls'
end

return M
