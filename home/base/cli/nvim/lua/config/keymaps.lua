vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

local map = vim.keymap.set
local opts = { noremap = true, silent = true }

-- buffer navigation
map("n", "<leader>bb", "<cmd>e #<cr>", opts)

-- windows navigation
map("n", "<leader>%", "<C-W>v", { desc = "Split Window Right", remap = true })
map("n", '<leader>"', "<C-W>s", { desc = "Split Window Below", remap = true })

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

-- undotree
map("n", "<leader>ut", function()
	require("undotree").open()
end, { desc = "Toggle Undotree" })

-- wrap selection
map("v", "s`", [[c`<C-r>"`<Esc>]], opts)
map("v", 's"', [[c"<C-r>""<Esc>]], opts)
map("v", "s(", [[c(<C-r>")<Esc>]], opts)
map("v", "s[", [[c[<C-r>"]<Esc>]], opts)
map("v", "s{", [[c{<C-r>"}<Esc>]], opts)
map("v", "s<", [[c<<C-r>"><Esc>]], opts)

-- auto close pairs
map("i", "`", "``<left>")
map("i", '"', '""<left>')
map("i", "(", "()<left>")
map("i", "[", "[]<left>")
map("i", "{", "{}<left>")

-- move text up and down
map("n", "<C-j>", ":m .+1<CR>==", opts)
map("n", "<C-k>", ":m .-2<CR>==", opts)
map("v", "<C-j>", ":m '>+1<CR>gv=gv", opts)
map("v", "<C-k>", ":m '<-2<CR>gv=gv", opts)

-- jump mark to the file and go to the last exit of the buffer
local function remap_uppercase_marks()
	for i = string.byte("A"), string.byte("Z") do
		local mark = string.char(i)
		map("n", "`" .. mark, function()
			vim.cmd("normal! `" .. mark .. "'\"zz")
		end, opts)
	end
end
remap_uppercase_marks()

-- Restart session and restore window, buffer layout
local session_file = vim.fn.stdpath("state") .. "/Session.vim"
vim.keymap.set("n", "ZR", function()
	vim.cmd("wall")
	vim.cmd("mksession! " .. vim.fn.fnameescape(session_file))
	vim.cmd("restart source " .. vim.fn.fnameescape(session_file))
end, { silent = true, desc = "Restart and restore session" })
