local group = vim.api.nvim_create_augroup("BlinkCmpLazyLoad", { clear = true })

vim.api.nvim_create_autocmd("InsertEnter", {
	pattern = "*",
	group = group,
	once = true,
	callback = function()
		require("blink.cmp").setup({
			keymap = {
				-- 'enter' for enter to accept
				-- <tab>/<s-tab>: move to right/left of your snippet expansion
				-- <c-space>: Open menu or open docs if already open
				-- <c-n>/<c-p> or <up>/<down>: Select next/previous item
				-- <c-e>: Hide menu
				-- <c-k>: Toggle signature help
				preset = "enter", -- Changed to 'enter' so <CR> accepts completions
			},
			appearance = {
				nerd_font_variant = "mono",
				use_nvim_cmp_as_default = true,
			},
			completion = {
				documentation = { auto_show = false, auto_show_delay_ms = 500 },
				ghost_text = { enabled = false },
			},
			sources = {
				default = { "lsp", "path", "snippets", "buffer" },
			},
			snippets = { preset = "luasnip" },
			fuzzy = { implementation = "rust" },
			signature = { enabled = true },
		})
	end,
})
