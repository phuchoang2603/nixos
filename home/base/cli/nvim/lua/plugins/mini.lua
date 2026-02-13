return {
  {
    'echasnovski/mini.nvim',
    version = false,
    config = function()
      -- Better Around/Inside textobjects
      --
      -- Examples:
      --  - va)  - [V]isually select [A]round [)]paren
      --  - yinq - [Y]ank [I]nside [N]ext [Q]uote
      --  - ci'  - [C]hange [I]nside [']quote
      require('mini.ai').setup { n_lines = 500 }

      -- Add/delete/replace surroundings (brackets, quotes, etc.)
      --
      -- Examples:
      --  - saiw) - [S]urround [A]dd [I]nner [W]ord [)]Paren
      --  - sd'   - [S]urround [D]elete [']quotes
      --  - sr)'  - [S]urround [R]eplace [)] [']
      require('mini.surround').setup()

      -- Auto pairs
      require('mini.pairs').setup()

      -- Simple and easy statusline (if you prefer over lualine)
      -- require('mini.statusline').setup { use_icons = vim.g.have_nerd_font }

      -- You can also explore other mini modules:
      -- require('mini.comment').setup()  -- Better commenting (if you don't use Comment.nvim)
      -- require('mini.bracketed').setup()  -- Navigate through various brackets
      -- require('mini.bufremove').setup()  -- Better buffer deletion
      -- require('mini.move').setup()  -- Move lines and selections
      -- require('mini.splitjoin').setup()  -- Split and join arguments
    end,
  },
}
