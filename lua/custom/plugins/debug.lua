return {
  'mfussenegger/nvim-dap',
  dependencies = {
    { 'rcarriga/nvim-dap-ui', dependencies = { 'nvim-neotest/nvim-nio' } },
    { 'theHamsta/nvim-dap-virtual-text', opts = {} },
  },
  keys = {
    {
      '<F5>',
      function()
        require('dap').continue()
      end,
      desc = 'Debug: start / continue',
    },
    {
      '<F10>',
      function()
        require('dap').step_over()
      end,
      desc = 'Debug: step over',
    },
    {
      '<F11>',
      function()
        require('dap').step_into()
      end,
      desc = 'Debug: step into',
    },
    {
      '<F12>',
      function()
        require('dap').step_out()
      end,
      desc = 'Debug: step out',
    },
    {
      '<leader>jb',
      function()
        require('dap').toggle_breakpoint()
      end,
      desc = 'Debug: toggle breakpoint',
    },
    {
      '<leader>jB',
      function()
        vim.ui.input({ prompt = 'Breakpoint condition: ' }, function(value)
          if value then
            require('dap').set_breakpoint(value)
          end
        end)
      end,
      desc = 'Debug: conditional breakpoint',
    },
    {
      '<leader>jd',
      function()
        require('dap').continue()
      end,
      desc = 'Debug: start / continue',
    },
    {
      '<leader>jq',
      function()
        require('dap').terminate()
      end,
      desc = 'Debug: terminate',
    },
    {
      '<leader>jl',
      function()
        require('dap').run_last()
      end,
      desc = 'Debug: repeat last session',
    },
    {
      '<leader>ju',
      function()
        require('dapui').toggle()
      end,
      desc = 'Debug: toggle panels',
    },
    {
      '<leader>je',
      function()
        require('dapui').eval()
      end,
      mode = { 'n', 'x' },
      desc = 'Debug: evaluate expression',
    },
    {
      '<leader>jR',
      function()
        require('dap').repl.toggle()
      end,
      desc = 'Debug: REPL',
    },
  },
  config = function()
    local dap, ui = require 'dap', require 'dapui'
    ui.setup()
    dap.listeners.after.event_initialized['java-ui'] = function()
      ui.open()
    end
    -- Keep the final output visible after a test or application exits.
    vim.fn.sign_define('DapBreakpoint', { text = '●', texthl = 'DiagnosticError' })
    vim.fn.sign_define('DapBreakpointCondition', { text = '◆', texthl = 'DiagnosticWarn' })
    vim.fn.sign_define('DapStopped', { text = '▶', texthl = 'DiagnosticOk', linehl = 'Visual' })
  end,
}
