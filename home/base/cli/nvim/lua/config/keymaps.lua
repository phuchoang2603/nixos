vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

local map = vim.keymap.set
local opts = { noremap = true, silent = true }

-- buffer navigation
map("n", "<S-h>", "<cmd>bprevious<cr>", opts)
map("n", "<S-l>", "<cmd>bnext<cr>", opts)
map("n", "<leader>bb", "<cmd>e #<cr>", opts)

-- windows navigation
map("n", "<leader>%", "<C-W>v", { desc = "Split Window Right", remap = true })
map("n", '<leader>"', "<C-W>s", { desc = "Split Window Below", remap = true })

-- terminal
map("t", "<C-q>", "<c-\\><c-n>", { desc = "Enter Normal Mode" })

-- clear highlights on search when pressing <Esc> in normal mode
map("n", "<Esc>", "<cmd>nohlsearch<CR>", opts)

-- keep last yanked when pasting
map("v", "p", '"_dP"', opts)

-- stay indenting in visual mode
map("x", "<", "<gv", opts)
map("x", ">", ">gv", opts)

-- commenting
map("n", "gco", "o<esc>Vcx<esc><cmd>normal gcc<cr>fxa<bs>", opts)
map("n", "gcO", "O<esc>Vcx<esc><cmd>normal gcc<cr>fxa<bs>", opts)

-- add undo break-points
map("i", ",", ",<c-g>u")
map("i", ".", ".<c-g>u")
map("i", ";", ";<c-g>u")

-- wrap selection
map("v", 's"', [[c"<C-r>""<Esc>]], opts)
map("v", "s(", [[c(<C-r>")<Esc>]], opts)
map("v", "s{", [[c{<C-r>"}<Esc>]], opts)
map("v", "s[", [[c[<C-r>"]<Esc>]], opts)

-- auto close pairs
map("i", "`", "``<left>")
map("i", '"', '""<left>')
map("i", "(", "()<left>")
map("i", "[", "[]<left>")
map("i", "{", "{}<left>")
map("i", "<", "<><left>")

-- move text up and down
map("n", "<C-j>", ":m .+1<CR>==", opts)
map("n", "<C-k>", ":m .-2<CR>==", opts)
map("v", "<C-j>", ":m '>+1<CR>gv=gv", opts)
map("v", "<C-k>", ":m '<-2<CR>gv=gv", opts)
