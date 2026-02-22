local group = vim.api.nvim_create_augroup("BlinkCmpLazyLoad", { clear = true })

vim.api.nvim_create_autocmd("InsertEnter", {
	pattern = "*",
	group = group,
	once = true,
	callback = function()
		require("luasnip.loaders.from_vscode").lazy_load()
		require("blink.cmp").setup({
			keymap = {
				preset = "enter",

				["<Tab>"] = { "fallback" },
				["<S-Tab>"] = { "fallback" },

				["<C-l>"] = { "snippet_forward", "fallback" },
				["<C-h>"] = { "snippet_backward", "fallback" },

				["<C-space>"] = { "show", "show_documentation", "hide_documentation" },
				["<C-e>"] = { "hide" },
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
