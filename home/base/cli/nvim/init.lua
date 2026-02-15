-- [[ Load core configuration ]]
require 'core.filetypes'
require 'core.options'
require 'core.keymaps'

-- [[ lazy.nvim plugin manager ]]
-- Note: lazy.nvim is installed via Nix (programs.neovim.plugins)
-- No need to bootstrap from GitHub - it's already on the runtimepath!

-- [[ Configure and install plugins ]]
-- Automatically import all plugin configurations from lua/plugins/
local plugins = { { import = 'plugins' } }
-- Manually load LSP plugins (they are arrays of plugin specs)
local lsp_specs = require 'lsp.lsp'
local format_spec = require 'lsp.format'
local lint_spec = require 'lsp.lint'

-- Add LSP specs (lsp.lua returns an array)
for _, spec in ipairs(lsp_specs) do
  table.insert(plugins, spec)
end

-- Add format spec (returns single spec)
table.insert(plugins, format_spec)

-- Add lint specs (returns an array)
for _, spec in ipairs(lint_spec) do
  table.insert(plugins, spec)
end

require('lazy').setup(plugins)
