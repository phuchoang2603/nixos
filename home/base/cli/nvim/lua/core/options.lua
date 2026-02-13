-- [[ Setting options ]]
vim.g.mapleader = ' '
vim.g.maplocalleader = '\\'
vim.g.have_nerd_font = true

vim.o.mouse = 'a'
vim.o.number = true
vim.o.relativenumber = true
vim.o.showmode = false
vim.o.signcolumn = 'yes'
vim.o.cursorline = true

-- Sync clipboard between OS and Neovim.
vim.schedule(function() vim.o.clipboard = 'unnamedplus' end)

-- Enable line wrap, linebreak
vim.opt.wrap = true
vim.opt.linebreak = true

-- indent stuff
vim.o.breakindent = true
vim.o.autoindent = true
vim.o.shiftwidth = 4
vim.o.tabstop = 4
vim.o.softtabstop = 4
vim.o.expandtab = true

-- Save undo history
vim.o.undofile = true

-- Case-insensitive searching UNLESS \C or one or more capital letters in the search term
vim.o.ignorecase = true
vim.o.smartcase = true

-- Decrease update time
vim.o.updatetime = 250

-- Decrease mapped sequence wait time
vim.o.timeoutlen = 300

-- Configure how new splits should be opened
vim.o.splitright = true
vim.o.splitbelow = true

--  Notice listchars is set using `vim.opt` instead of `vim.o`.
--  It is very similar to `vim.o` but offers an interface for conveniently interacting with tables.
--   See `:help lua-options`
--   and `:help lua-guide-options`
vim.o.list = true
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }

-- Preview substitutions live, as you type!
vim.o.inccommand = 'split'

-- Minimal number of screen lines to keep above and below the cursor.
vim.o.scrolloff = 16

-- Disable swap file
vim.opt.swapfile = false

-- if performing an operation that would fail due to unsaved changes in the buffer (like `:q`),
-- instead raise a dialog asking if you wish to save the current file(s)
-- See `:help 'confirm'`
vim.o.confirm = true

-- Folding configuration
-- Start with all folds open (use zM to close all, zR to open all, za to toggle)
vim.o.foldlevel = 99
vim.o.foldlevelstart = 99
