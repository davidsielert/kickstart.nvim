-- You can add your own plugins here or in other files in this directory!
--  I promise not to create any merge conflicts in this directory :)
--
-- See the kickstart.nvim README for more information
return {
  {
    'MeanderingProgrammer/render-markdown.nvim',
    ft = { 'markdown' },
    cmd = 'RenderMarkdown',
    dependencies = {
      'nvim-treesitter/nvim-treesitter',
      'echasnovski/mini.nvim',
    },
    keys = {
      { '<leader>mt', '<cmd>RenderMarkdown toggle<CR>', desc = '[M]arkdown Render [T]oggle' },
      { '<leader>me', '<cmd>RenderMarkdown enable<CR>', desc = '[M]arkdown Render [E]nable' },
    },
    opts = {},
  },
}
