-- VimTeX configuration
vim.g.vimtex_view_method = "zathura"
vim.g.vimtex_view_general_viewer = "zathura"
vim.g.vimtex_mappings_prefix = "<leader>l"

-- Filetype specific description for Which-Key (if you use it)
vim.api.nvim_create_autocmd("FileType", {
	pattern = "tex",
	callback = function()
		vim.keymap.set("n", "<leader>l", "", { desc = "+vimtex", buffer = true })
	end,
})

-- Markdown preview
require("live-preview").setup({})

vim.api.nvim_create_autocmd("FileType", {
	pattern = "markdown",
	callback = function(event)
		vim.keymap.set("n", "<leader>cp", "<cmd>LivePreview start<cr>", { desc = "Start Preview", buffer = event.buf })
		vim.keymap.set("n", "<leader>cx", "<cmd>LivePreview close<cr>", { desc = "Stop Preview", buffer = event.buf })
	end,
})
