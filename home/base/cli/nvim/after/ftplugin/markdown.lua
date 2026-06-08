require("live-preview").setup()

vim.keymap.set("n", "<leader>mp", "<cmd>LivePreview start<cr>", {
	desc = "Start Preview",
	buffer = true,
})

vim.keymap.set("n", "<leader>mc", "<cmd>LivePreview close<cr>", {
	desc = "Close Preview",
	buffer = true,
})

vim.keymap.set("n", "<leader>mm", "<cmd>LivePreview pick<cr>", {
	desc = "Pick Preview",
	buffer = true,
})
