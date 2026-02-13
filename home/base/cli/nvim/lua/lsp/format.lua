-- Format Configuration (conform.nvim)
-- Loads formatters from lua/config/lsp-configs.lua

-- Load all language configurations from the central config file
local lang_configs = require 'config.lsp-configs'

-- Extract formatters from language configs
local formatters = {}

for _, config in pairs(lang_configs) do
  if config.format then
    formatters = vim.tbl_deep_extend('force', formatters, config.format)
  end
end

return {
  'stevearc/conform.nvim',
  event = { 'BufWritePre' },
  cmd = { 'ConformInfo' },
  keys = {
    {
      '<leader>f',
      function()
        require('conform').format { async = true, lsp_format = 'fallback' }
      end,
      mode = '',
      desc = 'Format buffer',
    },
  },
  opts = function()
    return {
      notify_on_error = true,
      format_on_save = function(bufnr)
        -- Disable "format_on_save lsp_fallback" for languages that don't
        -- have a well standardized coding style. You can add additional
        -- languages here or re-enable it for the disabled ones.
        local disable_filetypes = {}
        if disable_filetypes[vim.bo[bufnr].filetype] then
          return nil
        else
          return {
            timeout_ms = 500,
            lsp_format = 'fallback',
          }
        end
      end,
      formatters_by_ft = formatters,
    }
  end,
}
