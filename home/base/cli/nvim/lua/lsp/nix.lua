-- Nix language configuration
local utils = require 'lsp.utils'

return {
  lsp = {
    nil_ls = {
      root_dir = utils.get_root_dir { 'flake.nix', 'default.nix', 'shell.nix', '.git' },
      settings = {
        ['nil'] = {
          nix = {
            flake = {
              autoArchive = true,
            },
          },
          formatting = {
            command = { 'nixfmt' },
          },
        },
      },
    },
  },
  format = {
    nix = { 'nixfmt' },
  },
  lint = {
    nix = { 'nix', 'statix' },
  },
}
