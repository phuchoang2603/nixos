-- Clear highlights on search when pressing <Esc> in normal mode
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

-- For conciseness
local opts = { noremap = true, silent = true }

-- Move cursor in Insert Mode using Alt
vim.keymap.set('i', '<A-h>', '<Left>', opts)
vim.keymap.set('i', '<A-j>', '<Down>', opts)
vim.keymap.set('i', '<A-k>', '<Up>', opts)
vim.keymap.set('i', '<A-l>', '<Right>', opts)

-- Highlight when yanking (copying) text
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function() vim.hl.on_yank() end,
})

-- Keep last yanked when pasting
vim.keymap.set('v', 'p', '"_dP"', opts)

-- stay indenting in visual mode
vim.keymap.set('x', '<', '<gv', opts)
vim.keymap.set('x', '>', '>gv', opts)

-- commenting
vim.keymap.set('n', 'gco', 'o<esc>Vcx<esc><cmd>normal gcc<cr>fxa<bs>', opts)
vim.keymap.set('n', 'gcO', 'O<esc>Vcx<esc><cmd>normal gcc<cr>fxa<bs>', opts)

-- Buffer navigation
vim.keymap.set('n', '<S-h>', '<cmd>bprevious<cr>', opts)
vim.keymap.set('n', '<S-l>', '<cmd>bnext<cr>', opts)
vim.keymap.set('n', '<leader>bb', '<cmd>e #<cr>', opts)
vim.keymap.set('n', '<leader>bd', function() Snacks.bufdelete() end, opts)
vim.keymap.set('n', '<leader>bo', function() Snacks.bufdelete.other() end, opts)

-- Windows navigation
vim.keymap.set('n', '<C-h>', '<C-w>h', opts)
vim.keymap.set('n', '<C-l>', '<C-w>l', opts)
vim.keymap.set('n', '<C-j>', '<C-w>j', opts)
vim.keymap.set('n', '<C-k>', '<C-w>k', opts)
vim.keymap.set('n', '<C-d>', '<C-w>c', opts)
