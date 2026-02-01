return {
  {
    "folke/snacks.nvim",
    opts = {
      scroll = {
        enabled = false, -- Disable scrolling animations
      },
      dashboard = {
        sections = {
          { section = "header" },
          { section = "keys", padding = 1 },
          { section = "recent_files", padding = 1 },
          { section = "startup" },
        },
      },
      explorer = {
        enabled = false,
      },
    },
    keys = {
      { "<leader>e", false },
      { "<leader>E", false },
    },
  },
}
