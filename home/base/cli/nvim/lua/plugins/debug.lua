local dap = require("dap")
local dapview = require("dap-view")
local dapgo = require("dap-go")
local dappython = require("dap-python")
local dapvirtualtext = require("nvim-dap-virtual-text")

dapvirtualtext.setup()

dapgo.setup()
dappython.setup("python3")

local keymaps = {
	{
		"<leader>db",
		function()
			dap.toggle_breakpoint()
		end,
		desc = "Toggle Breakpoint",
	},
	{
		"<leader>dc",
		function()
			dap.continue()
		end,
		desc = "Continue",
	},
	{
		"<leader>ds",
		function()
			dap.terminate()
			dapview.close()
		end,
		desc = "Stop Debugging",
	},
	{
		"<leader>dt",
		function()
			dapview.toggle()
		end,
		desc = "Toggle DAP View",
	},
	{
		"<leader>dw",
		"<cmd>DapViewWatch<cr>",
		desc = "DAP Watch",
	},
}

for _, km in ipairs(keymaps) do
	vim.keymap.set("n", km[1], km[2], { desc = km.desc })
end
