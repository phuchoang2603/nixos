require("live-preview").setup()

vim.keymap.set("n", "<leader>cp", "<cmd>LivePreview start<cr>", {
	desc = "Start Preview",
	buffer = true,
})
