local function augroup(name)
	return vim.api.nvim_create_augroup("user_" .. name, { clear = true })
end

-- LSP
local servers = {
	"sqruff",
	"bashls",
	"clangd",
	"gopls",
	"protols",
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
	"terraformls",
	"tflint",
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
		keys = "<leader>uc",
		func = function()
			local copilot_active = false
			local clients = vim.lsp.get_clients({ name = "copilot" })
			if #clients > 0 then
				copilot_active = true
			end

			local next_state = not copilot_active

			if next_state then
				vim.lsp.enable("copilot")
				vim.lsp.inline_completion.enable(true)
				require("sidekick.nes").enable()
			else
				for _, client in ipairs(clients) do
					client:stop(false)
				end
				vim.lsp.inline_completion.enable(false)
				require("sidekick.nes").disable()
			end

			local status_text = next_state and "ON" or "OFF"
			local icon = next_state and "󰚩 " or "󱚧 "
			vim.notify(
				string.format("%s Copilot LSP: %s", icon, status_text),
				vim.log.levels.INFO,
				{ title = "LSP Completion" }
			)
		end,
		desc = "Toggle Copilot LSP & Suggestions",
	},
	{
		keys = "<leader>ul",
		func = function()
			if vim.lsp.codelens.is_enabled() then
				vim.lsp.codelens.enable(false)
				vim.notify("Code Lenses: OFF", vim.log.levels.INFO, { title = "LSP Code Lenses" })
			else
				vim.lsp.codelens.enable(true)
				vim.notify("Code Lenses: ON", vim.log.levels.INFO, { title = "LSP Code Lenses" })
			end
		end,
		desc = "Toggle Code Lenses",
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
