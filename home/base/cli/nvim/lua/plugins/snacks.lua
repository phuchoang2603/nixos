local Snacks = require("snacks")

vim.api.nvim_set_hl(0, "SnacksDim", { fg = "#444444", bg = "NONE" })

Snacks.setup({
	bigfile = { enabled = true },
	quickfile = { enabled = true },
	explorer = {
		replace_netrw = true,
		trash = true,
	},
	notifier = { enabled = true },
	dim = {
		scope = {
			min_size = 3,
			max_size = 10,
			siblings = true,
		},
	},
	scope = { enabled = true },
	statuscolumn = { enabled = true },
	toggle = { enabled = true },
	indent = { enabled = true },
	gitbrowse = {
		enabled = true,
		what = "repo",
	},

	picker = {
		actions = {
			sidekick_send = function(...)
				return require("sidekick.cli.picker.snacks").send(...)
			end,
		},
		win = {
			input = {
				keys = {
					["<a-a>"] = {
						"sidekick_send",
						mode = { "n", "i" },
					},
				},
			},
		},
		sources = {
			files = {
				hidden = true,
				ignored = true,
				win = {
					input = {
						keys = {
							["<S-h>"] = "toggle_hidden",
							["<S-i>"] = "toggle_ignored",
							["<S-f>"] = "toggle_follow",
						},
					},
				},
				exclude = {
					"**/.git/*",
					"**/node_modules/*",
					"**/.yarn/cache/*",
					"**/.yarn/install*",
					"**/.yarn/releases/*",
					"**/.pnpm-store/*",
					"**/.idea/*",
					"**/.DS_Store",
					"build/*",
					"coverage/*",
					"dist/*",
					"hodor-types/*",
					"**/target/*",
					"**/public/*",
					"**/digest*.txt",
					"**/.node-gyp/**",
				},
			},
			grep = {
				hidden = true,
				ignored = true,
				exclude = {
					"**/.git/*",
					"**/node_modules/*",
					"**/.yarn/cache/*",
					"**/.yarn/install*",
					"**/.yarn/releases/*",
					"**/.pnpm-store/*",
					"**/.venv/*",
					"**/.idea/*",
					"**/.DS_Store",
					"**/yarn.lock",
					"build*/*",
					"coverage/*",
					"dist/*",
					"certificates/*",
					"hodor-types/*",
					"**/target/*",
					"**/public/*",
					"**/digest*.txt",
					"**/.node-gyp/**",
				},
			},
			explorer = {
				hidden = true,
				ignored = true,
				exclude = {
					".git",
					".pnpm-store",
					".venv",
					".DS_Store",
					"**/.node-gyp/**",
				},
				layout = { layout = { position = "right" } },
				win = {
					list = {
						keys = {
							["x"] = "explorer_move",
							["]h"] = "explorer_git_next",
							["[h"] = "explorer_git_prev",
						},
					},
				},
			},
		},
	},
})

local keymaps = {
	{
		"<leader><space>",
		function()
			Snacks.picker.smart()
		end,
		desc = "Smart Find Files",
	},
	{
		"<leader>/",
		function()
			Snacks.picker.grep()
		end,
		desc = "Grep",
	},
	{
		"<leader>:",
		function()
			Snacks.picker.command_history()
		end,
		desc = "Command History",
	},
	{
		"<leader>f",
		function()
			Snacks.explorer()
		end,
		desc = "File Explorer",
	},

	-- buffers
	{
		"<leader>bd",
		function()
			Snacks.bufdelete()
		end,
		desc = "Delete buffer",
		mode = { "n" },
	},
	{
		"<leader>bo",
		function()
			Snacks.bufdelete.other()
		end,
		desc = "Delete other buffers",
		mode = { "n" },
	},
	{
		"<leader>,",
		function()
			Snacks.picker.buffers({
				win = {
					input = {
						keys = {
							["dd"] = "bufdelete",
							["<c-d>"] = { "bufdelete", mode = { "n", "i" } },
						},
					},
					list = { keys = { ["dd"] = "bufdelete" } },
				},
			})
		end,
		desc = "Buffers",
	},

	-- git
	{
		"<leader>gb",
		function()
			Snacks.picker.git_branches()
		end,
		desc = "Git Branches",
	},
	{
		"<leader>gl",
		function()
			Snacks.picker.git_log()
		end,
		desc = "Git Log",
	},
	{
		"<leader>gL",
		function()
			Snacks.picker.git_log_line()
		end,
		desc = "Git Log Line",
	},
	{
		"<leader>gf",
		function()
			Snacks.picker.git_log_file()
		end,
		desc = "Git Log File",
	},
	{
		"<leader>gs",
		function()
			Snacks.picker.git_status()
		end,
		desc = "Git Status",
	},
	{
		"<leader>gd",
		function()
			Snacks.picker.git_diff()
		end,
		desc = "Git Diff Picker",
	},
	{
		"<leader>go",
		function()
			Snacks.gitbrowse()
		end,
		desc = "Git Browse",
	},
	{
		"<leader>gg",
		function()
			Snacks.lazygit()
		end,
		desc = "Lazygit",
	},

	-- search
	{
		"<leader>sw",
		function()
			Snacks.picker.grep_word()
		end,
		desc = "Visual selection or word",
		mode = { "n", "x" },
	},
	{
		"<leader>s/",
		function()
			Snacks.picker.lines()
		end,
		desc = "Buffer Lines",
	},
	{
		"<leader>sd",
		function()
			Snacks.picker.diagnostics()
		end,
		desc = "Diagnostics",
	},
	{
		"<leader>sD",
		function()
			Snacks.picker.diagnostics_buffer()
		end,
		desc = "Buffer Diagnostics",
	},
	{
		"<leader>sj",
		function()
			Snacks.picker.jumps()
		end,
		desc = "Jumps",
	},
	{
		"<leader>sl",
		function()
			Snacks.picker.loclist()
		end,
		desc = "Location List",
	},
	{
		"<leader>sn",
		function()
			Snacks.picker.notifications()
		end,
		desc = "Notification History",
	},
	{
		"<leader>sm",
		function()
			Snacks.picker.marks()
		end,
		desc = "Marks",
	},
	{
		"<leader>sr",
		function()
			Snacks.picker.recent()
		end,
		desc = "Recent",
	},
	{
		"<leader>su",
		function()
			Snacks.picker.undo()
		end,
		desc = "Undo History",
	},
	{
		"<leader>sq",
		function()
			Snacks.picker.qflist()
		end,
		desc = "Quickfix List",
	},
	{
		"<leader>st",
		function()
			require("todo-comments").setup()
			Snacks.picker.todo_comments()
		end,
		desc = "Todo comments",
	},

	-- LSP
	{
		"gd",
		function()
			Snacks.picker.lsp_definitions()
		end,
		desc = "Goto Definition",
	},
	{
		"gD",
		function()
			Snacks.picker.lsp_declarations()
		end,
		desc = "Goto Declaration",
	},
	{
		"gr",
		function()
			Snacks.picker.lsp_references()
		end,
		nowait = true,
		desc = "References",
	},
	{
		"gI",
		function()
			Snacks.picker.lsp_implementations()
		end,
		desc = "Goto Implementation",
	},
	{
		"gy",
		function()
			Snacks.picker.lsp_type_definitions()
		end,
		desc = "Goto Type Definition",
	},
	{
		"<leader>ss",
		function()
			Snacks.picker.lsp_symbols()
		end,
		desc = "LSP Symbols",
	},
	{
		"<leader>sS",
		function()
			Snacks.picker.lsp_workspace_symbols()
		end,
		desc = "LSP Workspace Symbols",
	},
	{
		"gai",
		function()
			Snacks.picker.lsp_incoming_calls()
		end,
		desc = "C[a]lls Incoming",
		has = "callHierarchy/incomingCalls",
	},
	{
		"gao",
		function()
			Snacks.picker.lsp_outgoing_calls()
		end,
		desc = "C[a]lls Outgoing",
		has = "callHierarchy/outgoingCalls",
	},

	-- Snacks Toggles (UI)
	{
		"<leader>uc",
		function()
			local core_enabled = vim.lsp.inline_completion.is_enabled()
			local next_state = not core_enabled

			-- Toggle Core Neovim Inline Completion
			vim.lsp.inline_completion.enable(next_state)

			-- Toggle Sidekick NES
			local nes = require("sidekick.nes")
			if next_state then
				nes.enable()
			else
				nes.disable()
			end

			local status_text = next_state and "ON" or "OFF"
			local icon = next_state and "󰚩 " or "󱚧 "
			vim.notify(
				string.format("%s Copilot & Inline: %s", icon, status_text),
				vim.log.levels.INFO,
				{ title = "LSP Completion" }
			)
		end,
		desc = "Toggle Copilot Suggestions",
	},
	{
		"<leader>uw",
		function()
			Snacks.toggle.option("wrap", { name = "Wrap" }):toggle()
		end,
		desc = "Toggle Wrap",
	},
	{
		"<leader>ud",
		function()
			Snacks.toggle.dim():toggle()
		end,
		desc = "Toggle Dim",
	},
	{
		"<leader>ux",
		function()
			Snacks.toggle.diagnostics():toggle()
		end,
		desc = "Toggle Diagnostics",
	},
	{
		"<leader>uh",
		function()
			Snacks.toggle.treesitter():toggle()
		end,
		desc = "Toggle Treesitter highlighting",
	},
	{
		"<leader>ui",
		function()
			Snacks.toggle.inlay_hints():toggle()
		end,
		desc = "Toggle Inlay Hints",
	},
}

for _, map in ipairs(keymaps) do
	local opts = { desc = map.desc }
	if map.silent ~= nil then
		opts.silent = map.silent
	end
	if map.noremap ~= nil then
		opts.noremap = map.noremap
	else
		opts.noremap = true
	end
	if map.expr ~= nil then
		opts.expr = map.expr
	end

	local mode = map.mode or "n"
	vim.keymap.set(mode, map[1], map[2], opts)
end
