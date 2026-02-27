local group = vim.api.nvim_create_augroup("BlinkCmpLazyLoad", { clear = true })

vim.api.nvim_create_autocmd("InsertEnter", {
	pattern = "*",
	group = group,
	once = true,
	callback = function()
		require("blink.cmp").setup({
			keymap = {
				preset = "none",
				["<C-space>"] = { "show", "show_documentation", "hide_documentation" },
				["<C-e>"] = { "hide", "fallback" },
				["<CR>"] = { "accept", "fallback" },

				["<C-l>"] = { "snippet_forward", "fallback" },
				["<C-h>"] = { "snippet_backward", "fallback" },

				["<C-p>"] = { "select_prev", "fallback_to_mappings" },
				["<C-n>"] = { "select_next", "fallback_to_mappings" },

				["<C-b>"] = { "scroll_documentation_up", "fallback" },
				["<C-f>"] = { "scroll_documentation_down", "fallback" },

				["<C-k>"] = { "show_signature", "hide_signature", "fallback" },
			},
			appearance = {
				nerd_font_variant = "mono",
				use_nvim_cmp_as_default = true,
			},
			completion = {
				list = { selection = { preselect = false, auto_insert = false } },
				documentation = { auto_show = false, auto_show_delay_ms = 500 },
				ghost_text = { enabled = false },
			},
			sources = {
				default = { "lsp", "path", "snippets", "buffer" },
			},
			fuzzy = { implementation = "rust" },
			signature = { enabled = true },
		})
	end,
})
