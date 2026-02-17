local wk = require("which-key")
wk.setup({
	preset = "helix",
})

wk.add({
	{ "<leader>b", group = "Buffer" },
	{ "<leader>c", group = "Code" },
	{ "<leader>g", group = "Git" },
	{ "<leader>u", group = "UI" },
	{ "<leader>s", group = "Search", mode = { "n", "v" } },
	{ "<leader>o", group = "Opencode" },
	{ "<leader>x", group = "Diagnostics/Quickfi[x]" },
})
