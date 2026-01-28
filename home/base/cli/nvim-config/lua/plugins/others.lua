return {
  { "nmac427/guess-indent.nvim", opts = { auto_cmd = true, override_editorconfig = true } },
  {
    "chrisgrieser/nvim-spider",
    opts = {},
    keys = {
      {
        "w",
        "<cmd>lua require('spider').motion('w')<CR>",
        mode = { "n", "o", "x" },
        desc = "Move to start of next of word",
      },
      {
        "e",
        "<cmd>lua require('spider').motion('e')<CR>",
        mode = { "n", "o", "x" },
        desc = "Move to end of word",
      },
      {
        "b",
        "<cmd>lua require('spider').motion('b')<CR>",
        mode = { "n", "o", "x" },
        desc = "Move to start of previous word",
      },
    },
  },
  { "nvim-mini/mini.pairs", enabled = true, },
  {
    "wintermute-cell/gitignore.nvim",
    config = function()
      require("gitignore")
    end,
  },
  {
    "lervag/vimtex",
    lazy = false, -- we don't want to lazy load VimTeX
    init = function()
      vim.g.maplocalleader = " "
      vim.g.vimtex_view_method = 'zathura'
      vim.g.vimtex_view_general_viewer = 'zathura'
    end,
  },
}
