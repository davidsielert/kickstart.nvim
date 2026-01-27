return {
  { -- Highlight, edit, and navigate code
    'nvim-treesitter/nvim-treesitter',
    branch = 'main', -- Use main branch for v1.0+ API
    build = ':TSUpdate',
    lazy = false, -- treesitter does not support lazy-loading
    config = function()
      -- [[ Configure Treesitter ]] See `:help nvim-treesitter`

      -- Install parsers for common languages
      local parsers = { 'bash', 'c', 'html', 'lua', 'luadoc', 'markdown', 'markdown_inline', 'vim', 'vimdoc', 'query' }
      require('nvim-treesitter').install(parsers)

      -- Enable treesitter highlighting for all filetypes with installed parsers
      vim.api.nvim_create_autocmd('FileType', {
        group = vim.api.nvim_create_augroup('treesitter-highlight', { clear = true }),
        callback = function(ev)
          -- Check if a parser is available for this filetype
          if pcall(vim.treesitter.start, ev.buf) then
            -- Enable indentation based on treesitter
            vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
          end
        end,
      })

      -- Auto-install parsers when opening a file with a missing parser
      vim.api.nvim_create_autocmd('FileType', {
        group = vim.api.nvim_create_augroup('treesitter-auto-install', { clear = true }),
        callback = function(ev)
          local ft = ev.match
          local lang = vim.treesitter.language.get_lang(ft) or ft
          if not pcall(vim.treesitter.language.inspect, lang) then
            -- Parser not installed, try to install it
            pcall(function()
              require('nvim-treesitter').install(lang)
            end)
          end
        end,
      })

      -- There are additional nvim-treesitter modules that you can use to interact
      -- with nvim-treesitter. You should go explore a few and see what interests you:
      --
      --    - Incremental selection: Included, see `:help nvim-treesitter-incremental-selection-mod`
      --    - Show your current context: https://github.com/nvim-treesitter/nvim-treesitter-context
      --    - Treesitter + textobjects: https://github.com/nvim-treesitter/nvim-treesitter-textobjects
    end,
  },
}
-- vim: ts=2 sts=2 sw=2 et
