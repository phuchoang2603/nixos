-- Load all language configurations from the central config file
local lang_configs = require 'lsp.lsp-configs'

-- Extract linters from language configs
local linters_by_ft = {}
for _, config in pairs(lang_configs) do
  if config.lint then linters_by_ft = vim.tbl_deep_extend('force', linters_by_ft, config.lint) end
end

return {
  {
    'mfussenegger/nvim-lint',
    event = { 'BufReadPost', 'BufNewFile', 'BufWritePost' },
    config = function()
      local lint = require 'lint'
      lint.linters_by_ft = linters_by_ft

      vim.api.nvim_create_autocmd({ 'BufWritePost', 'BufReadPost', 'InsertLeave' }, {
        group = vim.api.nvim_create_augroup('nvim-lint', { clear = true }),
        callback = function() lint.try_lint() end,
      })
    end,
  },
}
