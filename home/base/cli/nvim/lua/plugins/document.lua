-- VimTeX configuration
local is_mac = vim.loop.os_uname().sysname == "Darwin"

if is_mac then
	vim.g.vimtex_view_method = "skim"
	vim.g.vimtex_view_general_viewer = "skim"
else
	vim.g.vimtex_view_method = "zathura"
	vim.g.vimtex_view_general_viewer = "zathura"
end

vim.g.vimtex_mappings_prefix = "<leader>l"

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
	end,
})
