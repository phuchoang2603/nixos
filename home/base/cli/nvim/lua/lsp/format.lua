-- Format Configuration (conform.nvim)
-- Loads formatters from language-specific files in lua/lsp/*.lua

-- Helper function to load all language formatter configurations
local function load_formatters()
  local lang_files = vim.fn.glob(vim.fn.stdpath 'config' .. '/lua/lsp/*.lua', false, true)
  local merged_formatters = {}

  -- Files to skip (not language configs)
  local skip_files = { 'lsp', 'format', 'lint', 'utils', 'vimtex' }

  for _, file in ipairs(lang_files) do
    local lang_name = vim.fn.fnamemodify(file, ':t:r')

    if not vim.tbl_contains(skip_files, lang_name) then
      local ok, lang_config = pcall(require, 'lsp.' .. lang_name)
      if ok and lang_config.format then
        -- Merge formatter configs
        merged_formatters = vim.tbl_deep_extend('force', merged_formatters, lang_config.format)
      end
    end
  end

  return merged_formatters
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
      formatters_by_ft = load_formatters(),
    }
  end,
}
