-- Here is a more advanced example where we pass configuration
-- options to `gitsigns.nvim`. This is equivalent to the following lua:
--    require('gitsigns').setup({ ... })
--
-- See `:help gitsigns` to understand what the configuration keys do
return {
  { -- Adds git related signs to the gutter, as well as utilities for managing changes
    'lewis6991/gitsigns.nvim',
    opts = {
      on_attach = function(buf)
        local gs = require 'gitsigns'
        local function map(key, action, desc)
          vim.keymap.set('n', key, action, { buffer = buf, desc = desc })
        end
        map(']c', function()
          if vim.wo.diff then
            vim.cmd.normal { ']c', bang = true }
          else
            gs.nav_hunk 'next'
          end
        end, 'Next Git change')
        map('[c', function()
          if vim.wo.diff then
            vim.cmd.normal { '[c', bang = true }
          else
            gs.nav_hunk 'prev'
          end
        end, 'Previous Git change')
        map('<leader>hp', gs.preview_hunk, 'Preview Git change')
        map('<leader>hs', gs.stage_hunk, 'Stage Git change')
        vim.keymap.set('x', '<leader>hs', function()
          gs.stage_hunk { vim.fn.line '.', vim.fn.line 'v' }
        end, { buffer = buf, desc = 'Stage selected Git changes' })
      end,
      signs = {
        add = { text = '+' },
        change = { text = '~' },
        delete = { text = '_' },
        topdelete = { text = '‾' },
        changedelete = { text = '~' },
      },
    },
  },
}
-- vim: ts=2 sts=2 sw=2 et
