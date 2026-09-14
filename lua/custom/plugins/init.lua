-- You can add your own plugins here or in other files in this directory!
--  I promise not to create any merge conflicts in this directory :)
--
-- See the kickstart.nvim README for more information
return {
  {
    'MeanderingProgrammer/render-markdown.nvim',
    dependencies = {
      'nvim-treesitter/nvim-treesitter',
      'echasnovski/mini.nvim',
    },
    keys = {
      { '<leader>me', '<cmd>RenderMarkdown enable<CR>', desc = '[M]arkdown Render [E]nable' },
    },
    opts = {},
  },
}
