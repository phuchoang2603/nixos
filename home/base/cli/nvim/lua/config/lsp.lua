local function augroup(name)
	return vim.api.nvim_create_augroup("user_" .. name, { clear = true })
end

-- LSP
local servers = {
	"bashls",
	"sqls",
	"sqruff",
	"clangd",
	"gopls",
	"protols",
	"rust_analyzer",
	"html",
	"cssls",
	"jsonls",
	"tsgo",
	"lua_ls",
	"markdown_oxide",
	"texlab",
	"harper_ls",
	"nixd",
	"ty",
	"ruff",
	"ansiblels",
	"terraformls",
	"taplo",
	"yamlls",
	"docker_language_server",
	"helm_ls",
	"tilt_ls",
}
vim.lsp.enable(servers)

-- Keymaps
local default_keymaps = {
	{ keys = "<leader>ca", func = vim.lsp.buf.code_action, desc = "Code Actions" },
	{ keys = "<leader>cr", func = vim.lsp.buf.rename, desc = "Code Rename" },
	{ keys = "<leader>cf", func = vim.lsp.buf.format, desc = "Code Format" },
	{ keys = "<leader>cl", func = vim.lsp.codelens.run, desc = "Run Code Lens", has = "codeLensProvider" },
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
	{
		mode = "i",
		keys = "<c-b>",
		func = function()
			local result = vim.lsp.inline_completion.get({
				on_accept = function(item)
					local insert_text = item.insert_text
					if type(insert_text) ~= "string" or insert_text == "" then
						return item
					end

					local cursor_col = vim.fn.col(".") - 1
					local current_line = vim.fn.getline(".")
					local typed_so_far = current_line:sub(1, cursor_col)

					local remaining = ""
					if insert_text:sub(1, #typed_so_far) == typed_so_far then
						remaining = insert_text:sub(#typed_so_far + 1)
					else
						remaining = insert_text
					end

					local next_chunk = remaining:match("^%s*%S+")

					if next_chunk then
						item.insert_text = typed_so_far .. next_chunk
						return item
					end

					return item
				end,
			})
			if not result then
				return "<c-b>"
			end
		end,
		expr = true,
		desc = "Accept partial Copilot Suggestions",
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
