local function augroup(name)
	return vim.api.nvim_create_augroup("user_" .. name, { clear = true })
end

-- LSP
local servers = {
	"basedpyright",
	"bashls",
	"clangd",
	"cssls",
	"copilot",
	"docker_language_server",
	"gopls",
	"helm_ls",
	"html",
	"jsonls",
	"lua_ls",
	"marksman",
	"nixd",
	"ruff",
	"taplo",
	"terraformls",
	"tflint",
	"yamlls",
}
vim.lsp.enable(servers)

-- Keymaps
local default_keymaps = {
	{ keys = "<leader>ca", func = vim.lsp.buf.code_action, desc = "Code Actions" },
	{ keys = "<leader>cr", func = vim.lsp.buf.rename, desc = "Code Rename" },
	{ keys = "<leader>cf", func = vim.lsp.buf.format, desc = "Code Format" },
	{
		keys = "<leader>uc",
		func = function()
			local is_enabled = vim.lsp.inline_completion.is_enabled()
			vim.lsp.inline_completion.enable(not is_enabled)
			vim.notify("Copilot: " .. (not is_enabled and "Enabled" or "Disabled"))
		end,
		desc = "Toggle Copilot Suggestions",
	},
	{
		mode = "i",
		keys = "<Tab>",
		func = function()
			if not vim.lsp.inline_completion.get() then
				return "<Tab>"
			end
		end,
		desc = "Accept Copilot Suggestions",
	},
	{ keys = "<leader>k", func = vim.lsp.buf.hover, desc = "Hover Documentation", has = "hoverProvider" },
	{ keys = "K", func = vim.lsp.buf.hover, desc = "Hover (alt)", has = "hoverProvider" },
	{ keys = "gd", func = vim.lsp.buf.definition, desc = "Goto Definition", has = "definitionProvider" },
}

-- Events
vim.api.nvim_create_autocmd("LspAttach", {
	group = augroup("lsp_attach"),
	callback = function(args)
		local client = vim.lsp.get_client_by_id(args.data.client_id)
		local buf = args.buf
		if client then
			-- Native Inline Completion
			if client:supports_method("textDocument/inlineCompletion") then
				vim.lsp.inline_completion.enable(true, { bufnr = buf })
			end

			-- Inlay hints
			if client:supports_method("textDocument/inlayHint") then
				vim.lsp.inlay_hint.enable(true, { bufnr = args.buf })
			end

			if client:supports_method("textDocument/documentColor") then
				vim.lsp.document_color.enable(true, args.buf, {
					style = "background",
				})
			end

			-- Configure Keymaps
			for _, km in ipairs(default_keymaps) do
				-- Only bind if there's no `has` requirement, or the server supports it
				if not km.has or client.server_capabilities[km.has] then
					vim.keymap.set(
						km.mode or "n",
						km.keys,
						km.func,
						{ buffer = buf, desc = "LSP: " .. km.desc, nowait = km.nowait }
					)
				end
			end
		end
	end,
})
