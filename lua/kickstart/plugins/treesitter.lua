return {
  {
    'nvim-treesitter/nvim-treesitter',
    branch = 'main',
    build = ':TSUpdate',
    lazy = false,
    config = function()
      local treesitter = require 'nvim-treesitter'
      local parsers = {
        'bash',
        'c',
        'cpp',
        'css',
        'go',
        'gomod',
        'gosum',
        'hcl',
        'html',
        'java',
        'xml',
        'javascript',
        'json',
        'lua',
        'luadoc',
        'markdown',
        'markdown_inline',
        'python',
        'query',
        'rust',
        'svelte',
        'tsx',
        'typescript',
        'vim',
        'vimdoc',
        'yaml',
      }

      local function start(buf)
        if not vim.api.nvim_buf_is_loaded(buf) or vim.bo[buf].buftype ~= '' then
          return
        end
        local lang = vim.treesitter.language.get_lang(vim.bo[buf].filetype)
        if lang and vim.list_contains(parsers, lang) then
          pcall(vim.treesitter.start, buf, lang)
        end
      end

      vim.api.nvim_create_autocmd('FileType', {
        group = vim.api.nvim_create_augroup('treesitter-highlight', { clear = true }),
        callback = function(ev)
          start(ev.buf)
        end,
      })

      -- Installation is asynchronous; attach buffers opened before it finishes.
      treesitter.install(parsers):await(vim.schedule_wrap(function(err)
        if err then
          vim.notify('Tree-sitter installation failed: ' .. tostring(err), vim.log.levels.ERROR)
          return
        end
        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
          start(buf)
        end
      end))
      -- Keep native filetype indentation; Tree-sitter indentation is experimental.
    end,
  },
}
