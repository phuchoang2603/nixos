-- Register the custom filetypes Neovim doesn't know by default
vim.filetype.add({
	extension = {
		env = "dotenv",
		sarif = "sarif",
	},
	filename = {
		[".env"] = "dotenv",
		["env"] = "dotenv",
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
		["%.env%.[%w_.-]+"] = "dotenv",
	},
})
