local opts = { buffer = true, silent = true }

-- Build and View
vim.keymap.set("n", "<leader>lb", "<cmd>LspTexlabBuild<cr>", { buffer = true, desc = "TexLab: Build PDF" })
vim.keymap.set(
	"n",
	"<leader>lv",
	"<cmd>LspTexlabForward<cr>",
	{ buffer = true, desc = "TexLab: Forward Search (View)" }
)
vim.keymap.set("n", "<leader>lk", "<cmd>LspTexlabCancelBuild<cr>", { buffer = true, desc = "TexLab: Cancel Build" })

-- Cleaning
vim.keymap.set(
	"n",
	"<leader>lc",
	"<cmd>LspTexlabCleanAuxiliary<cr>",
	{ buffer = true, desc = "TexLab: Clean Aux Files" }
)
vim.keymap.set(
	"n",
	"<leader>lC",
	"<cmd>LspTexlabCleanArtifacts<cr>",
	{ buffer = true, desc = "TexLab: Clean All Artifacts" }
)

-- Environment Management
vim.keymap.set(
	"n",
	"<leader>le",
	"<cmd>LspTexlabFindEnvironments<cr>",
	{ buffer = true, desc = "TexLab: List Environments" }
)
vim.keymap.set(
	"n",
	"<leader>lr",
	"<cmd>LspTexlabChangeEnvironment<cr>",
	{ buffer = true, desc = "TexLab: Rename Environment" }
)

-- Misc
vim.keymap.set(
	"n",
	"<leader>lg",
	"<cmd>LspTexlabDependencyGraph<cr>",
	{ buffer = true, desc = "TexLab: Show Dependency Graph" }
)
