return {
  {
    'nvim-java/nvim-java',
    ft = 'java',
    dependencies = { 'MunifTanjim/nui.nvim', 'mfussenegger/nvim-dap', 'hrsh7th/cmp-nvim-lsp' },
    config = function()
      require('custom.java').setup()
    end,
  },
  {
    'stevearc/aerial.nvim',
    cmd = { 'AerialToggle', 'AerialOpen' },
    keys = { { '<leader>jo', '<cmd>AerialToggle!<CR>', desc = 'Java: symbol outline' } },
    opts = { backends = { 'lsp', 'treesitter' }, layout = { default_direction = 'right' } },
  },
}
