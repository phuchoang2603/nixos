return {
  {
    "NickvanDyke/opencode.nvim",
    dependencies = { "folke/snacks.nvim" },
    init = function()
      vim.g.opencode_opts = {
        auto_reload = true,
        provider = {
          enabled = "snacks",
        },
        override = function(cmd, opts)
          -- Use tmux instead of neovim terminal
          local tmux_cmd = string.format("tmux split-window -h '%s'", cmd or "opencode")
          vim.fn.system(tmux_cmd)
        end,
      }
    end,
    keys = {
      {
        "<leader>oa",
        function()
          require("opencode").ask("@this: ", { submit = true })
        end,
        mode = { "n", "x" },
        desc = "Ask opencode",
      },
      {
        "<leader>ox",
        function()
          require("opencode").select()
        end,
        mode = { "n", "x" },
        desc = "Execute opencode action...",
      },
      {
        "<leader>og",
        function()
          require("opencode").prompt("@this")
        end,
        mode = { "n", "x" },
        desc = "Add to opencode",
      },
      {
        "<leader>ot",
        function()
          require("opencode").toggle()
        end,
        mode = { "n", "t" },
        desc = "Toggle opencode",
      },
    },
  },
}
