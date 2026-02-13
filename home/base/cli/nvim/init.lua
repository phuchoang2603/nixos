-- [[ Load core configuration ]]
require 'core.options'
require 'core.keymaps'

-- [[ Install `lazy.nvim` plugin manager ]]
local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = 'https://github.com/folke/lazy.nvim.git'
  local out = vim.fn.system { 'git', 'clone', '--filter=blob:none', '--branch=stable', lazyrepo, lazypath }
  if vim.v.shell_error ~= 0 then error('Error cloning lazy.nvim:\n' .. out) end
end

---@type vim.Option
local rtp = vim.opt.rtp
rtp:prepend(lazypath)

-- [[ Configure and install plugins ]]
-- Automatically import all plugin configurations from lua/plugins/
-- Manually load LSP plugins (they are arrays of plugin specs)
local lsp_specs = require 'lsp.lsp'
local format_spec = require 'lsp.format'
local lint_spec = require 'lsp.lint'

local plugins = { { import = 'plugins' } }

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
