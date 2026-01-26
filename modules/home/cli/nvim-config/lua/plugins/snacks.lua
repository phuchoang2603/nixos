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
          { section = "projects", padding = 1 },
          {
            section = "terminal",
            enabled = function()
              return Snacks.git.get_root() ~= nil
            end,
            cmd = "git status --short --branch --renames",
            height = 5,
            padding = 1,
            ttl = 5 * 60,
          },
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
