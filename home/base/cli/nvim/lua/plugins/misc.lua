return {
  { 'NMAC427/guess-indent.nvim', opts = {} },
  {
    'folke/todo-comments.nvim',
    optional = true,
    dependencies = { 'nvim-lua/plenary.nvim' },
    keys = {
      { '<leader>st', function() Snacks.picker.todo_comments() end, desc = 'Todo' },
      { '<leader>sT', function() Snacks.picker.todo_comments { keywords = { 'TODO', 'FIX', 'FIXME' } } end, desc = 'Todo/Fix/Fixme' },
    },
  },
  {
    'chrisgrieser/nvim-spider',
    opts = {},
    keys = {
      {
        'w',
        "<cmd>lua require('spider').motion('w')<CR>",
        mode = { 'n', 'o', 'x' },
        desc = 'Move to start of next of word',
      },
      {
        'e',
        "<cmd>lua require('spider').motion('e')<CR>",
        mode = { 'n', 'o', 'x' },
        desc = 'Move to end of word',
      },
      {
        'b',
        "<cmd>lua require('spider').motion('b')<CR>",
        mode = { 'n', 'o', 'x' },
        desc = 'Move to start of previous word',
      },
    },
  },
}
