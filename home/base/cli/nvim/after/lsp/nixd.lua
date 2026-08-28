local hostname = vim.fn.hostname()

local flake_base = "(builtins.getFlake (builtins.toString ./.))."
local options_expr = flake_base .. "nixosConfigurations." .. hostname .. ".options"

---@type vim.lsp.Config
return {
	cmd = { "nixd" },
	filetypes = { "nix" },
	root_markers = { "flake.nix", ".git" },
	settings = {
		nixd = {
			nixpkgs = {
				expr = "import " .. flake_base .. "inputs.nixpkgs { }",
			},
			formatting = {
				command = { "nixfmt" },
			},
			options = {
				nixos = {
					expr = options_expr,
				},
				["home-manager"] = {
					expr = options_expr .. ".home-manager.users.type.getSubOptions []",
				},
			},
		},
	},
}
