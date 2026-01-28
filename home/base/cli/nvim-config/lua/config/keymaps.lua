-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local map = LazyVim.safe_keymap_set

-- Move cursor in Insert Mode using Alt
map("i", "<A-h>", "<Left>", { desc = "Move Cursor Left" })
map("i", "<A-j>", "<Down>", { desc = "Move Cursor Down" })
map("i", "<A-k>", "<Up>", { desc = "Move Cursor Up" })
map("i", "<A-l>", "<Right>", { desc = "Move Cursor Right" })

-- Turn off default leader l for lazy
map("n", "<leader>L", "<cmd>Lazy<cr>", { desc = "Lazy" })
