return {
  {
    'mfussenegger/nvim-lint',
    opts = {
      linters = {
        ['markdownlint-cli2'] = {
          prepend_args = { '--config', vim.env.HOME .. '/.config/nvim/lua/config/.markdownlint-cli2.yaml', '--' },
        },
      },
    },
  },
  {
    'arminveres/md-pdf.nvim',
    branch = 'main',
    lazy = true,
    keys = {
      {
        '<leader>cp',
        function() require('md-pdf').convert_md_to_pdf() end,
        desc = 'Markdown preview',
      },
    },
    ---@type md-pdf.config
    opts = {
      toc = false,
      title_page = false,
    },
  },
}
