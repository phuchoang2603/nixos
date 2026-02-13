-- Markdown language configuration
local utils = require 'lsp.utils'

return {
  lsp = {
    marksman = {
      root_dir = utils.get_root_dir { '.marksman.toml', '.git' },
    },
  },
  format = {
    markdown = { 'prettierd', 'prettier', stop_after_first = true },
    ['markdown.mdx'] = { 'prettierd', 'prettier', stop_after_first = true },
  },
  lint = {
    markdown = { 'markdownlint-cli2' },
  },
  -- Additional plugins for Markdown support
  plugins = {
    {
      'arminveres/md-pdf.nvim',
      branch = 'main',
      lazy = true,
      keys = {
        {
          '<leader>cp',
          function()
            require('md-pdf').convert_md_to_pdf()
          end,
          desc = 'Markdown preview',
        },
      },
      opts = {
        toc = false,
        title_page = false,
      },
    },
  },
}
