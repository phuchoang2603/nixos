local is_mac = vim.loop.os_uname().sysname == "Darwin"

if is_mac then
	vim.g.vimtex_view_method = "skim"
	vim.g.vimtex_view_general_viewer = "skim"
else
	vim.g.vimtex_view_method = "zathura"
	vim.g.vimtex_view_general_viewer = "zathura"
end

vim.g.vimtex_mappings_prefix = "<leader>l"

vim.keymap.set("n", "<leader>l", "", { desc = "+vimtex", buffer = true })
