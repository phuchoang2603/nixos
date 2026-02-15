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
      on_attach = function(bufnr)
        local gs = package.loaded.gitsigns

        local function map(mode, l, r, opts)
          opts = opts or {}
          opts.buffer = bufnr
          vim.keymap.set(mode, l, r, opts)
        end

        -- Navigation
        map('n', ']g', function()
          if vim.wo.diff then return ']g' end
          vim.schedule(function() gs.next_hunk() end)
          return '<Ignore>'
        end, { expr = true, desc = 'Next Git Hunk' })

        map('n', '[g', function()
          if vim.wo.diff then return '[g' end
          vim.schedule(function() gs.prev_hunk() end)
          return '<Ignore>'
        end, { expr = true, desc = 'Prev Git Hunk' })

        -- Actions
        map('n', '<leader>ghs', gs.stage_hunk, { desc = 'Stage Hunk' })
        map('n', '<leader>ghr', gs.reset_hunk, { desc = 'Reset Hunk' })
        map('v', '<leader>ghs', function() gs.stage_hunk { vim.fn.line '.', vim.fn.line 'v' } end, { desc = 'Stage Hunk' })
        map('v', '<leader>ghr', function() gs.reset_hunk { vim.fn.line '.', vim.fn.line 'v' } end, { desc = 'Reset Hunk' })
        map('n', '<leader>ghu', gs.undo_stage_hunk, { desc = 'Undo Stage Hunk' })
        map('n', '<leader>ghp', gs.preview_hunk, { desc = 'Preview Hunk' })
        map('n', '<leader>ghb', function() gs.blame_line { full = true } end, { desc = 'Blame Line' })
      end,
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
