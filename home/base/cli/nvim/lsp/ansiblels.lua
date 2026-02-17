---@brief
---
--- https://github.com/ansible/vscode-ansible
---
--- Language server for the ansible configuration management tool.
---
--- `ansible-language-server` can be installed via `npm`:
---
--- ```sh
--- npm install -g @ansible/ansible-language-server
--- ```

---@type vim.lsp.Config
return {
	cmd = { "ansible-language-server", "--stdio" },
	handlers = {
		["workspace/configuration"] = function(err, result, ctx, config)
			if err then
				return nil
			end
			local status, res = pcall(vim.lsp.handlers["workspace/configuration"], err, result, ctx, config)
			if not status then
				return nil
			end
			return res
		end,
	},
	settings = {
		ansible = {
			python = {
				interpreterPath = "python",
			},
			ansible = {
				path = "ansible",
			},
			executionEnvironment = {
				enabled = false,
			},
			validation = {
				enabled = true,
				lint = {
					enabled = true,
					path = "ansible-lint",
				},
			},
		},
	},
	filetypes = { "yaml.ansible" },
	root_markers = { "ansible.cfg", ".ansible-lint" },
}
