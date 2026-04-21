local function augroup(name)
	return vim.api.nvim_create_augroup("user_" .. name, { clear = true })
end

-- LSP
local servers = {
	"bashls",
	"clangd",
	"cssls",
	"copilot",
	"docker_language_server",
	"gopls",
	"harper_ls",
	"helm_ls",
	"html",
	"jsonls",
	"lua_ls",
	"protols",
	"markdown_oxide",
	"nixd",
	"ruff",
	"taplo",
	"terraformls",
	"texlab",
	"tflint",
	"tilt_ls",
	"tsgo",
	"ty",
	"sqruff",
	"yamlls",
}
vim.lsp.enable(servers)

-- Keymaps
local default_keymaps = {
	{ keys = "<leader>ca", func = vim.lsp.buf.code_action, desc = "Code Actions" },
	{ keys = "<leader>cr", func = vim.lsp.buf.rename, desc = "Code Rename" },
	{ keys = "<leader>cf", func = vim.lsp.buf.format, desc = "Code Format" },
	{ keys = "<leader>k", func = vim.lsp.buf.hover, desc = "Hover Documentation", has = "hoverProvider" },
	{ keys = "K", func = vim.lsp.buf.hover, desc = "Hover (alt)", has = "hoverProvider" },
	{ keys = "gd", func = vim.lsp.buf.definition, desc = "Goto Definition", has = "definitionProvider" },
	{
		mode = "i",
		keys = "<Tab>",
		func = function()
			if vim.lsp.inline_completion.get() then
				return
			end

			return "<Tab>"
		end,
		expr = true,
		desc = "Accept Copilot Suggestions or Tab",
	},
}

-- Events
vim.api.nvim_create_autocmd("LspAttach", {
	group = augroup("lsp_attach"),
	callback = function(args)
		local client = vim.lsp.get_client_by_id(args.data.client_id)
		local buf = args.buf
		if client then
			for _, km in ipairs(default_keymaps) do
				if not km.has or client.server_capabilities[km.has] then
					vim.keymap.set(
						km.mode or "n",
						km.keys,
						km.func,
						{ buffer = buf, desc = "LSP: " .. km.desc, nowait = km.nowait, expr = km.expr }
					)
				end
			end
		end
	end,
})

-- Loading Progress
vim.api.nvim_create_autocmd("LspProgress", {
	callback = function(ev)
		local value = ev.data.params.value
		vim.api.nvim_echo({ { value.message or "done" } }, false, {
			id = "lsp." .. ev.data.client_id,
			kind = "progress",
			source = "vim.lsp",
			title = value.title,
			status = value.kind ~= "end" and "running" or "success",
			percent = value.percentage,
		})
	end,
})
