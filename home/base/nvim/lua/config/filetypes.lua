-- Register the custom filetypes Neovim doesn't know by default
vim.filetype.add({
	extension = {
		env = "dotenv",
	},
	filename = {
		[".env"] = "dotenv",
		["env"] = "dotenv",
		["go.work"] = "gowork",
		["docker-compose.yaml"] = "yaml.docker-compose",
		["docker-compose.yml"] = "yaml.docker-compose",
		["compose.yaml"] = "yaml.docker-compose",
		["compose.yml"] = "yaml.docker-compose",
		[".gitlab-ci.yml"] = "yaml.gitlab",
	},
	pattern = {
		-- Match Helm templates (usually in a 'templates' folder)
		[".*/templates/.*%.yaml"] = "helm",
		[".*/templates/.*%.tpl"] = "gotmpl",
		-- Terraform vars
		[".*%.tfvars"] = "terraform-vars",
		-- Web stuff
		["[jt]sconfig.*.json"] = "jsonc",
		["%.env%.[%w_.-]+"] = "dotenv",
	},
})
