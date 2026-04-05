local wk = require("which-key")
wk.setup({
	preset = "helix",
})

wk.add({
	{ "<leader>a", group = "AI" },
	{ "<leader>b", group = "Buffer" },
	{ "<leader>c", group = "Code" },
	{ "<leader>g", group = "Git" },
	{ "<leader>u", group = "UI" },
	{ "<leader>s", group = "Search", mode = { "n", "v" } },
	{ "<leader>t", group = "Test" },
})
