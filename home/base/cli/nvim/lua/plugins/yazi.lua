vim.api.nvim_create_autocmd("UIEnter", {
	callback = function()
		require("yazi").setup({
			open_for_directories = false,
		})
	end,
})

-- Keymap
local map = vim.keymap.set

-- Open yazi at the current file (Normal and Visual mode)
map({ "n", "v" }, "<leader>e", "<cmd>Yazi<cr>", { desc = "Open yazi at the current file", silent = true })

-- Open yazi at the root working directory
map("n", "<leader>E", "<cmd>Yazi cwd<cr>", { desc = "Open yazi at root directory", silent = true })
