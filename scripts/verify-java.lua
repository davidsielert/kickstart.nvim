-- Run with the normal config: nvim --headless -i NONE '+luafile scripts/verify-java.lua'
local root = vim.env.NVIM_JAVA_VERIFY_DIR or vim.fn.tempname()
local function write(path, contents)
  vim.fn.mkdir(vim.fs.dirname(root .. '/' .. path), 'p')
  vim.fn.writefile(vim.split(contents, '\n', { plain = true }), root .. '/' .. path)
end

local function wait_for(label, predicate, timeout)
  assert(vim.wait(timeout or 60000, predicate, 100), 'Timed out: ' .. label)
  print('PASS ' .. label)
end

local function verify()
  write(
    'pom.xml',
    [[<project xmlns="http://maven.apache.org/POM/4.0.0">
  <modelVersion>4.0.0</modelVersion><groupId>dev.check</groupId><artifactId>java-editor-check</artifactId><version>1.0</version>
  <properties><maven.compiler.release>11</maven.compiler.release><project.build.sourceEncoding>UTF-8</project.build.sourceEncoding></properties>
  <dependencies><dependency><groupId>org.junit.jupiter</groupId><artifactId>junit-jupiter</artifactId><version>5.11.4</version><scope>test</scope></dependency></dependencies>
  <build><plugins><plugin><groupId>org.apache.maven.plugins</groupId><artifactId>maven-compiler-plugin</artifactId><version>3.13.0</version></plugin><plugin><groupId>org.apache.maven.plugins</groupId><artifactId>maven-surefire-plugin</artifactId><version>3.5.2</version></plugin></plugins></build>
</project>]]
  )
  write(
    'src/main/java/dev/check/App.java',
    [[package dev.check;

public class App {
    public static int add(int a, int b) {
        int result = a + b;
        return result;
    }

    public static void main(String[] args) {
        int answer = add(20, 22);
        System.out.println("JAVA_DEBUG_OK=" + answer);
    }
}
]]
  )
  write(
    'src/test/java/dev/check/AppTest.java',
    [[package dev.check;

import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.assertEquals;

class AppTest {
    @Test
    void addsNumbers() {
        assertEquals(42, App.add(20, 22));
    }
}
]]
  )
  local runtime = assert(require('custom.java').runtimes())
  local jdk11 = vim.iter(runtime.runtimes):find(function(r)
    return r.name == 'JavaSE-11'
  end)
  assert(jdk11, 'Install JDK 11 to verify the coursework runtime')
  local build = vim.system({ 'mvn', '-q', 'test' }, { cwd = root, env = { JAVA_HOME = jdk11.path }, text = true }):wait(120000)
  assert(build.code == 0, build.stderr or 'Maven failed')
  print 'PASS Maven test on JDK 11'
  local source = root .. '/src/main/java/dev/check/App.java'
  vim.cmd.edit(source)
  local buf = vim.api.nvim_get_current_buf()
  local client
  wait_for('exactly one initialized Java client', function()
    local clients = vim.lsp.get_clients { bufnr = buf, name = 'jdtls' }
    client = clients[1]
    return #clients == 1 and client.initialized
  end, 120000)
  local uri = vim.uri_from_bufnr(buf)
  local function request(method, params)
    local response, err = client:request_sync(method, params, 60000, buf)
    assert(response and not response.err, vim.inspect(response or err))
    return response.result
  end
  assert(client.config.root_dir == (vim.uv.fs_realpath(root) or root))
  local symbols = request('textDocument/documentSymbol', { textDocument = { uri = uri } })
  assert(#symbols > 0, 'No document symbols')
  print 'PASS project root, document symbols'
  assert(request('java/buildWorkspace', true) == 1, 'JDT compilation failed')
  print 'PASS JDT project compilation'
  local hover = request('textDocument/hover', { textDocument = { uri = uri }, position = { line = 9, character = 22 } })
  assert(hover and hover.contents, 'No hover information')
  local completion = request('textDocument/completion', { textDocument = { uri = uri }, position = { line = 10, character = 19 } })
  assert(completion and #(completion.items or completion) > 0, 'No completions')
  local definitions = request('textDocument/definition', { textDocument = { uri = uri }, position = { line = 9, character = 22 } })
  assert(definitions and #definitions > 0, 'No definition')
  print 'PASS hover, completion, go to definition'
  assert(pcall(vim.treesitter.get_parser, buf, 'java'))
  local original = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  vim.api.nvim_buf_set_lines(buf, 4, 5, false, { 'int result=a+b;' })
  require('conform').format { bufnr = buf, async = false, timeout_ms = 10000 }
  assert(vim.api.nvim_buf_get_lines(buf, 4, 5, false)[1]:find('int result = a + b;', 1, true), 'Java formatter did not run')
  vim.api.nvim_buf_set_lines(buf, 4, 5, false, { '        int result = "wrong";' })
  wait_for('Java type-error diagnostic', function()
    return vim.iter(vim.diagnostic.get(buf)):any(function(d)
      return d.severity == vim.diagnostic.severity.ERROR
    end)
  end)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, original)
  vim.cmd.write()
  wait_for('type-error diagnostic clears', function()
    return #vim.diagnostic.get(buf, { severity = vim.diagnostic.severity.ERROR }) == 0
  end)
  vim.api.nvim_buf_set_lines(buf, 1, 1, false, { 'import java.util.List;' })
  require('custom.java').organize_imports()
  wait_for('organize imports removes unused import', function()
    return not table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), '\n'):find('import java.util.List;', 1, true)
  end)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, original)
  vim.cmd.write()
  print 'PASS Java parser and Conform formatting'
  vim.cmd 'AerialOpen'
  wait_for('outline contains class and methods', function()
    return require('aerial.data').has_symbols(buf)
  end)
  vim.cmd 'AerialClose'
  vim.api.nvim_set_current_buf(buf)
  local dap = require 'dap'
  local config
  wait_for('main-class discovery', function()
    config = vim.iter(dap.configurations.java or {}):find(function(c)
      return c.mainClass == 'dev.check.App'
    end)
    return config ~= nil
  end)
  config = vim.deepcopy(config)
  config.console = 'internalConsole'
  local stopped, exited, output = false, false, ''
  dap.listeners.after.event_stopped['verify-java'] = function()
    stopped = true
  end
  dap.listeners.after.event_terminated['verify-java'] = function()
    exited = true
  end
  dap.listeners.after.event_output['verify-java'] = function(_, event)
    output = output .. event.output
  end
  vim.api.nvim_win_set_cursor(0, { 11, 0 })
  dap.toggle_breakpoint()
  dap.run(config)
  wait_for('debugger stops at breakpoint', function()
    return stopped and dap.session() and dap.session().current_frame
  end)
  local value
  local session = assert(dap.session())
  assert(session.config.javaExec:find(jdk11.path, 1, true), 'Debugger did not select JDK 11: ' .. session.config.javaExec)
  session:request('evaluate', { expression = 'answer', frameId = session.current_frame.id, context = 'repl' }, function(err, result)
    assert(not err, vim.inspect(err))
    value = result.result
  end)
  wait_for('debugger evaluates answer = 42', function()
    return value == '42'
  end)
  dap.continue()
  wait_for('debuggee prints expected output and exits', function()
    return exited and output:find('JAVA_DEBUG_OK=42', 1, true)
  end)
  wait_for('debug session closes', function()
    return dap.session() == nil
  end)
  dap.clear_breakpoints()
  require('dapui').close()
  vim.cmd.edit(root .. '/src/test/java/dev/check/AppTest.java')
  local testbuf = vim.api.nvim_get_current_buf()
  wait_for('test buffer reuses Java client', function()
    return #vim.lsp.get_clients { bufnr = testbuf, name = 'jdtls' } == 1
  end)
  local java_test = require 'java-test'
  local function finished_tests()
    local report = java_test.last_report
    if not report or not report.result_parser or dap.session() then
      return nil
    end
    local tests = {}
    local function collect(nodes)
      for _, node in ipairs(nodes or {}) do
        if node.children then
          collect(node.children)
        elseif not node.is_suite then
          table.insert(tests, node)
        end
      end
    end
    collect(report:get_results())
    local done = #tests > 0 and vim.iter(tests):all(function(test)
      return test.result and test.result.execution == 'ended'
    end)
    return done and tests or nil
  end
  local function assert_passed(label)
    local results
    wait_for(label, function()
      results = finished_tests()
      return results ~= nil
    end)
    assert(#results == 1 and not results[1].result.status, vim.inspect(results))
    require('dapui').close()
    vim.api.nvim_set_current_buf(testbuf)
  end
  java_test.last_report = nil
  java_test.run_current_class()
  assert_passed 'JUnit class runs through Neovim'
  vim.api.nvim_win_set_cursor(0, { 9, 0 })
  java_test.last_report = nil
  java_test.run_current_method()
  assert_passed 'nearest JUnit method runs through Neovim'
  vim.api.nvim_win_set_cursor(0, { 9, 0 })
  dap.toggle_breakpoint()
  stopped = false
  java_test.last_report = nil
  java_test.debug_current_method()
  wait_for('JUnit debugger stops at test breakpoint', function()
    return stopped and dap.session() and dap.session().current_frame
  end)
  dap.continue()
  assert_passed 'debugged JUnit test succeeds'
  print('JAVA_VERIFICATION_OK fixture=' .. root)
end

local ok, err = xpcall(verify, debug.traceback)
if not ok then
  io.stderr:write(tostring(err) .. '\nFixture: ' .. root .. '\n')
end
pcall(function()
  require('dap').close()
end)
for _, client in ipairs(vim.lsp.get_clients()) do
  client:stop(true)
end
vim.cmd(ok and 'qa!' or 'cquit 1')
