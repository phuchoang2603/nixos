local opt = vim.opt

opt.number = true -- Line numbers
opt.relativenumber = true -- Relative line numbers
opt.cursorline = true -- Highlight current line
opt.wrap = true -- Wrap lines
opt.linebreak = true -- Wrap based on word
opt.breakindent = true -- Keep indent when wrap
opt.scrolloff = 16 -- Keep 10 lines above/below cursor
opt.sidescrolloff = 8 -- Keep 8 columns left/right of cursor

-- Indentation
opt.tabstop = 2 -- Tab width
opt.shiftwidth = 2 -- Indent width
opt.softtabstop = 2 -- Soft tab stop
opt.expandtab = true -- Use spaces instead of tabs
opt.smartindent = true -- Smart auto-indenting
opt.autoindent = true -- Copy indent from current line

-- Search settings
opt.ignorecase = true -- Case insensitive search
opt.smartcase = true -- Case sensitive if uppercase in search
opt.hlsearch = true -- Highlight search results
opt.incsearch = true -- Show matches as you type

-- Visual settings
opt.signcolumn = "yes" -- Always show sign column
opt.showmatch = true -- Highlight matching brackets
opt.winborder = "rounded" -- Round popup window
vim.wo.foldmethod = "expr"
opt.foldlevel = 99 -- Start buffer unfold
opt.foldlevelstart = 99
opt.fillchars = {
	foldopen = " ",
	foldclose = " ",
	fold = " ",
	foldsep = " ",
	diff = "╱",
	eob = " ",
}

-- File handling
opt.confirm = true -- Confirm to save changes before exiting modified buffer
opt.backup = false -- Don't create backup files
opt.writebackup = false -- Don't create backup before writing
opt.swapfile = false -- Don't create swap files
opt.undofile = true -- Persistent undo
opt.autoread = true -- Auto reload files changed outside vim
opt.autowrite = true -- Auto save
opt.clipboard = vim.env.SSH_TTY and "" or "unnamedplus" -- Sync with system clipboard

-- Behavior settings
opt.mouse = "a" -- Enable mouse support
opt.splitbelow = true -- Horizontal splits go below
opt.splitright = true -- Vertical splits go right

-- Performance improvements
opt.redrawtime = 10000
opt.maxmempattern = 20000
opt.updatetime = 300 -- Faster completion
opt.timeoutlen = 300 -- Lower timeout key press

vim.g.autoformat = true
vim.g.trouble_lualine = true
vim.g.markdown_recommended_style = 0
