local M = {}

function M.check()
  local health = vim.health
  health.start 'Java development'
  local java = require 'custom.java'
  local runtime = java.runtimes()
  if runtime.home then
    health.ok('Language server JDK: ' .. runtime.home)
  else
    health.warn 'No local JDK 21+ found; nvim-java downloads its own JDK to run the language server'
  end
  for _, entry in ipairs(runtime.runtimes) do
    health.ok(entry.name .. ': ' .. entry.path .. (entry.default and ' (default for standalone files)' or ''))
  end
  local plugin = require('lazy.core.config').plugins['nvim-java']
  if plugin and plugin._.installed then
    health.ok 'nvim-java installed'
  else
    health.error('nvim-java missing', { ':Lazy install' })
  end
  local packages = vim.fn.stdpath 'data' .. '/nvim-java/packages/'
  for _, name in ipairs { 'jdtls', 'java-debug', 'java-test', 'lombok' } do
    if vim.fn.isdirectory(packages .. name) == 1 then
      health.ok(name .. ' installed')
    else
      health.warn(name .. ' not installed yet', { 'Open a Java file; nvim-java installs its tools on first use' })
    end
  end
  if vim.fn.executable 'java' == 1 then
    health.ok('java: ' .. vim.fn.exepath 'java')
  else
    health.error 'java is missing from PATH'
  end
  local ok = pcall(vim.treesitter.language.add, 'java')
  if ok then
    health.ok 'Java Tree-sitter parser available'
  else
    health.warn('Java parser missing', { ':TSInstall java' })
  end
  health.info 'Maven and Gradle projects use their build target; wrappers are preferred. Use :JavaSettingsChangeRuntime for unmanaged projects.'
end

return M
