-- Register the custom filetypes Neovim doesn't know by default
vim.filetype.add({
	extension = {
		env = "sh",
		sarif = "sarif",
	},
	filename = {
		[".env"] = "sh",
		["env"] = "sh",
		["go.work"] = "gowork",
		["docker-compose.yaml"] = "yaml.docker-compose",
		["docker-compose.yml"] = "yaml.docker-compose",
		["compose.yaml"] = "yaml.docker-compose",
		["compose.yml"] = "yaml.docker-compose",
		["Tiltfile"] = "starlark",
		[".gitlab-ci.yml"] = "yaml.gitlab",
	},
	pattern = {
		-- Terraform vars
		[".*%.tfvars"] = "terraform-vars",
		-- Web stuff
		["[jt]sconfig.*.json"] = "jsonc",
		["%.env%.[%w_.-]+"] = "sh",
		-- Ansible
		[".*/host_vars/.*%.ya?ml"] = "yaml.ansible",
		[".*/group_vars/.*%.ya?ml"] = "yaml.ansible",
		[".*/playbooks/.*%.ya?ml"] = "yaml.ansible",
		[".*/roles/.*/tasks/.*%.ya?ml"] = "yaml.ansible",
		[".*/roles/.*/handlers/.*%.ya?ml"] = "yaml.ansible",
		["site%.ya?ml"] = "yaml.ansible",
		["main%.ya?ml"] = "yaml.ansible",
	},
})
