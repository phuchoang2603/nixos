-- Lazyload DAP
local _dap_initialized = false
local function init_dap()
	if _dap_initialized then
		return
	end
	_dap_initialized = true

	-- Load the main modules
	local dapview = require("dap-view")
	local dapgo = require("dap-go")
	local dappython = require("dap-python")

	-- Run the setups
	dapview.setup({
		virtual_text = {
			enabled = true,
		},
		auto_toggle = true,
		follow_tab = true,
	})
	dapgo.setup()
	dappython.setup("python3")
end

-- Lazyload Neotest
local _neotest_initialized = false
local function init_neotest()
	if _neotest_initialized then
		return
	end
	_neotest_initialized = true

	local neotest = require("neotest")

	neotest.setup({
		discovery = { enabled = false },
		running = { concurrent = true },
		summary = { animated = false },
		output = {
			enabled = true,
			open_on_run = true,
		},
		adapters = {
			require("neotest-golang")({
				dap_go_enabled = true,
			}),
			require("neotest-python")({
				dap = { adapter = "python" },
			}),
		},
	})
end

local keymaps = {
	-- DAP keymaps
	{
		"<leader>db",
		function()
			init_dap()
			require("dap").toggle_breakpoint()
		end,
		desc = "Toggle Breakpoint",
	},
	{
		"<leader>dB",
		function()
			init_dap()
			require("dap").list_breakpoints()
			vim.cmd("copen")
		end,
		desc = "List Breakpoints",
	},
	{
		"<leader>dc",
		function()
			init_dap()
			require("dap").continue()
		end,
		desc = "Continue",
	},
	{
		"<leader>dC",
		function()
			init_dap()
			require("dap").run_to_cursor()
		end,
		desc = "Run to Cursor",
	},
	{
		"<leader>ds",
		function()
			init_dap()
			require("dap").terminate()
			require("dap-view").close()
		end,
		desc = "Stop Debugging",
	},

	-- Neotest keymaps
	{
		"<leader>tt",
		function()
			init_neotest()
			require("neotest").run.run()
		end,
		desc = "Run Nearest Test",
	},
	{
		"<leader>tf",
		function()
			init_neotest()
			require("neotest").run.run(vim.fn.expand("%"))
		end,
		desc = "Run Current File Tests",
	},
	{
		"<leader>tl",
		function()
			init_neotest()
			require("neotest").run.run_last()
		end,
		desc = "Run Last Test",
	},
	{
		"<leader>td",
		function()
			init_dap()
			init_neotest()
			require("neotest").run.run({ strategy = "dap" })
		end,
		desc = "Debug Nearest Test",
	},
	{
		"<leader>to",
		function()
			init_neotest()
			require("neotest").output.open({ enter = true, auto_close = true })
		end,
		desc = "Open Test Output",
	},
	{
		"<leader>ts",
		function()
			init_neotest()
			require("neotest").summary.toggle()
		end,
		desc = "Toggle Test Summary",
	},
}

for _, km in ipairs(keymaps) do
	vim.keymap.set("n", km[1], km[2], { desc = km.desc, silent = true })
end
