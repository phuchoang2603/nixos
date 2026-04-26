local hostname = vim.fn.hostname()
local is_darwin = vim.fn.has("mac") == 1 or vim.fn.has("macunix") == 1

-- Build the strings for nixd evaluation
local flake_base = "(builtins.getFlake (builtins.toString ./.))."
local config_type = is_darwin and "darwinConfigurations" or "nixosConfigurations"

local options_expr = flake_base .. config_type .. "." .. hostname .. ".options"

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
				[is_darwin and "darwin" or "nixos"] = {
					expr = options_expr,
				},
				["home-manager"] = {
					expr = options_expr .. ".home-manager.users.type.getSubOptions []",
				},
			},
		},
	},
}
