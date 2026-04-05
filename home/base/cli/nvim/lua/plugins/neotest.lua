local status, neotest = pcall(require, "neotest")
if not status then
	return
end

neotest.setup({
	discovery = {
		enabled = false,
	},
	running = {
		concurrent = true,
	},
	summary = {
		animated = false,
	},
	output = {
		enabled = true,
		open_on_run = true,
	},
	adapters = {
		require("neotest-golang"),
		require("neotest-python")({
			dap = { justMyCode = false },
		}),
	},
})

local keymaps = {
	{
		"<leader>tt",
		function()
			require("neotest").run.run()
		end,
		desc = "Run Nearest Test",
	},
	{
		"<leader>tf",
		function()
			require("neotest").run.run(vim.fn.expand("%"))
		end,
		desc = "Run Current File Tests",
	},
	{
		"<leader>tl",
		function()
			require("neotest").run.run_last()
		end,
		desc = "Run Last Test",
	},
	{
		"<leader>to",
		function()
			require("neotest").output.open({ enter = true, auto_close = true })
		end,
		desc = "Open Test Output",
	},
	{
		"<leader>ts",
		function()
			require("neotest").summary.toggle()
		end,
		desc = "Toggle Test Summary",
	},
	{
		"<leader>tw",
		function()
			require("neotest").watch.toggle(vim.fn.expand("%"))
		end,
		desc = "Toggle Test Watch",
	},
}

for _, keymap in ipairs(keymaps) do
	vim.keymap.set(keymap.mode or "n", keymap[1], keymap[2], { desc = keymap.desc, silent = true })
end
