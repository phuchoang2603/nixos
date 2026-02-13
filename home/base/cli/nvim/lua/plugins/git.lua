return {
  -- Git signs in the gutter
  {
    'lewis6991/gitsigns.nvim',
    opts = {
      signs = {
        add = { text = '+' },
        change = { text = '~' },
        delete = { text = '_' },
        topdelete = { text = '‾' },
        changedelete = { text = '~' },
      },
    },
  },

  -- Lazygit integration
  {
    'folke/snacks.nvim',
    opts = {
      lazygit = {
        -- automatically configure lazygit to use the current colorscheme
        -- and integrate edit with the current neovim instance
        configure = true,
      },
    },
    keys = {
      {
        '<leader>gg',
        function() Snacks.lazygit() end,
        desc = 'Lazygit (Root Dir)',
      },
      {
        '<leader>gf',
        function() Snacks.lazygit.log_file() end,
        desc = 'Lazygit Current File History',
      },
      {
        '<leader>gl',
        function() Snacks.lazygit.log() end,
        desc = 'Lazygit Log',
      },
      { '<leader>gd', function() Snacks.picker.git_diff() end, desc = 'Git Diff (hunks)' },
      { '<leader>gs', function() Snacks.picker.git_status() end, desc = 'Git Status' },
    },
  },

  -- Gitignore
  {
    'wintermute-cell/gitignore.nvim',
    config = function() require 'gitignore' end,
  },
}
