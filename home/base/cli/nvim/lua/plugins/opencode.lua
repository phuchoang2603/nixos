vim.g.opencode_opts = {
	auto_reload = true,
	provider = {
		enabled = "snacks",
		snacks = {
			auto_close = true,
			win = {
				position = "float",
				enter = true,
			},
		},
	},
}

local opencode = require("opencode")

local mappings = {
	{
		mode = { "n", "x" },
		lhs = "<leader>cq",
		rhs = function()
			opencode.ask("@this: ", { submit = true })
		end,
		desc = "Ask opencode",
	},
	{
		mode = { "n", "x" },
		lhs = "<leader>cx",
		rhs = function()
			opencode.select()
		end,
		desc = "Execute opencode action…",
	},
}

for _, map in ipairs(mappings) do
	vim.keymap.set(map.mode, map.lhs, map.rhs, { desc = "Opencode: " .. map.desc })
end
