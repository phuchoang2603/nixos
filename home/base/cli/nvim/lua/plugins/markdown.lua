return {
  {
    'mfussenegger/nvim-lint',
    event = { 'BufReadPre', 'BufNewFile' },
    config = function()
      local lint = require('lint')
      
      -- Configure linters by filetype
      lint.linters_by_ft = {
        markdown = { 'markdownlint-cli2' },
      }
      
      -- Customize markdownlint-cli2 linter
      lint.linters['markdownlint-cli2'].args = {
        '--config',
        vim.env.HOME .. '/.config/nvim/lua/config/.markdownlint-cli2.yaml',
        '--',
      }
      
      -- Auto-lint on events
      vim.api.nvim_create_autocmd({ 'BufEnter', 'BufWritePost', 'InsertLeave' }, {
        callback = function()
          lint.try_lint()
        end,
      })
    end,
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
