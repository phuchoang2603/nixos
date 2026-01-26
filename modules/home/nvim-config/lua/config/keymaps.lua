local map = vim.keymap.set

-- Move cursor in Insert Mode using Alt
map("i", "<A-h>", "<Left>", { desc = "Move Cursor Left" })
map("i", "<A-j>", "<Down>", { desc = "Move Cursor Down" })
map("i", "<A-k>", "<Up>", { desc = "Move Cursor Up" })
map("i", "<A-l>", "<Right>", { desc = "Move Cursor Right" })

-- Plugin manager
map("n", "<leader>L", "<cmd>Lazy<cr>", { desc = "Lazy" })
