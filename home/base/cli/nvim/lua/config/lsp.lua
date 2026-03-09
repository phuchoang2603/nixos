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
	{ keys = "<leader>k", func = vim.lsp.buf.hover, desc = "Hover Documentation", has = "hoverProvider" },
	{ keys = "K", func = vim.lsp.buf.hover, desc = "Hover (alt)", has = "hoverProvider" },
	{ keys = "gd", func = vim.lsp.buf.definition, desc = "Goto Definition", has = "definitionProvider" },
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
			-- If it's already enabled, try to accept a suggestion
			if vim.lsp.inline_completion.is_enabled() then
				if vim.lsp.inline_completion.get() then
					return ""
				end
			else
				-- If disabled, enable it and trigger a request
				vim.lsp.inline_completion.enable(true)
				return ""
			end
			return "<Tab>"
		end,
		expr = true,
		desc = "Accept Copilot Suggestions or Tab",
	},
	{
		mode = "i",
		keys = "<C-b>",
		func = function()
			local result = vim.lsp.inline_completion.get({ on_accept = AcceptCompletion })
			if not result then
				return "<C-b>"
			end
		end,
		expr = true,
		replace_keycodes = true,
		desc = "Accept Next Word of Copilot Suggestions",
	},
}

-- Events
vim.api.nvim_create_autocmd("LspAttach", {
	group = augroup("lsp_attach"),
	callback = function(args)
		local client = vim.lsp.get_client_by_id(args.data.client_id)
		local buf = args.buf
		if client then
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
						{ buffer = buf, desc = "LSP: " .. km.desc, nowait = km.nowait, expr = km.expr }
					)
				end
			end
		end
	end,
})

-- Helper for Partial Word Acceptance
function AcceptCompletion(item)
	local insert_text = item.insert_text
	if type(insert_text) == "string" then
		local range = item.range
		if range then
			local lines = vim.split(insert_text, "\n")
			local current_lines = vim.api.nvim_buf_get_text(
				range.start.buf,
				range.start.row,
				range.start.col,
				range.end_.row,
				range.end_.col,
				{}
			)

			local row = 1
			while row <= #lines and row <= #current_lines and lines[row] == current_lines[row] do
				row = row + 1
			end

			local col = 1
			while
				row <= #lines
				and col <= #lines[row]
				and row <= #current_lines
				and col <= #current_lines[row]
				and lines[row][col] == current_lines[row][col]
			do
				col = col + 1
			end

			local word = string.match(lines[row]:sub(col), "%s*[^%s]%w*")
			item.insert_text = table.concat(vim.list_slice(lines, 1, row - 1), "\n")
				.. (row <= #current_lines and "" or "\n")
				.. (row <= #lines and col <= #lines[row] and lines[row]:sub(1, col - 1) or "")
				.. word
		end
	end
	return item
end
