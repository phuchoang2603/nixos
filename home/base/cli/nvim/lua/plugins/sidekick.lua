require("sidekick").setup({
	nes = {
		enabled = false,
	},
	cli = {
		mux = {
			enabled = true,
			backend = "tmux",
			create = "window",
		},
	},
})

local keymaps = {
	{
		"<tab>",
		function()
			if not require("sidekick").nes_jump_or_apply() then
				return "<Tab>"
			end
		end,
		expr = true,
		desc = "Goto/Apply Next Edit Suggestion",
	},
	{
		"<leader>aa",
		function()
			require("sidekick.cli").toggle()
		end,
		desc = "Sidekick Toggle",
	},
	{
		"<leader>ad",
		function()
			require("sidekick.cli").close()
		end,
		desc = "Detach a CLI Session",
	},
	{
		"<leader>at",
		function()
			require("sidekick.cli").send({ msg = "{this}" })
		end,
		mode = { "x", "n" },
		desc = "Send This",
	},

	{
		"<leader>af",
		function()
			require("sidekick.cli").send({ msg = "{file}" })
		end,
		desc = "Send File",
	},
	{
		"<leader>av",
		function()
			require("sidekick.cli").send({ msg = "{selection}" })
		end,
		mode = { "x" },
		desc = "Send Visual Selection",
	},
	{
		"<leader>ap",
		function()
			require("sidekick.cli").prompt()
		end,
		mode = { "n", "x" },
		desc = "Sidekick Select Prompt",
	},
}

for _, keymap in ipairs(keymaps) do
	vim.keymap.set(keymap.mode or "n", keymap[1], keymap[2], { desc = keymap.desc, silent = true })
end
