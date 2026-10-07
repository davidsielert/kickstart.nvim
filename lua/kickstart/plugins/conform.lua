local prettier = { 'prettierd', 'prettier', stop_after_first = true }

return {
  {
    'stevearc/conform.nvim',
    lazy = false,
    keys = {
      {
        '<leader>uf',
        function()
          vim.b.disable_autoformat = not vim.b.disable_autoformat
          vim.notify('Format on save: ' .. (vim.b.disable_autoformat and 'off' or 'on') .. ' for this buffer')
        end,
        desc = 'Toggle format on save for buffer',
      },
      {
        '<leader>f',
        function()
          require('conform').format { async = true }
        end,
        mode = { 'n', 'v' },
        desc = 'Format buffer or selection',
      },
    },
    opts = {
      notify_on_error = true,
      default_format_opts = { lsp_format = 'fallback' },
      format_on_save = function(buf)
        if not vim.b[buf].disable_autoformat then
          return { timeout_ms = 1000 }
        end
      end,
      formatters_by_ft = {
        lua = { 'stylua' },
        java = { lsp_format = 'prefer' },
        python = { 'isort', 'black' },
        html = prettier,
        javascript = prettier,
        javascriptreact = prettier,
        typescript = prettier,
        typescriptreact = prettier,
        -- The Svelte server bundles Prettier and its Svelte plugin.
        svelte = { lsp_format = 'prefer' },
        css = prettier,
        scss = prettier,
        json = prettier,
        jsonc = prettier,
        yaml = prettier,
        markdown = prettier,
        hcl = { 'hcl' },
      },
    },
  },
}
