return {
  'stevearc/oil.nvim',
  lazy = false,
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  keys = {
    { '-', '<cmd>Oil<CR>', desc = 'Oil: open parent directory' },
    { '<leader>o', '<cmd>Oil --float<CR>', desc = 'Oil: browse directory' },
  },
  opts = {
    default_file_explorer = true,
    view_options = { show_hidden = true },
  },
}
