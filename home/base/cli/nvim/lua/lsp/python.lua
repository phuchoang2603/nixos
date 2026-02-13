-- Python language configuration
local utils = require 'lsp.utils'

return {
  lsp = {
    basedpyright = {
      root_dir = utils.get_root_dir {
        'pyproject.toml',
        'setup.py',
        'setup.cfg',
        'requirements.txt',
        'Pipfile',
        'pyrightconfig.json',
        '.git',
      },
      settings = {
        basedpyright = {
          analysis = {
            typeCheckingMode = 'standard',
            autoSearchPaths = true,
            diagnosticMode = 'openFilesOnly',
            useLibraryCodeForTypes = true,
            diagnosticSeverityOverrides = {
              reportUnusedVariable = 'warning',
              reportUnusedImport = 'warning',
            },
          },
        },
      },
    },
    ruff = {
      cmd_env = { RUFF_TRACE = 'messages' },
      init_options = {
        settings = {
          logLevel = 'error',
        },
      },
      keys = {
        {
          '<leader>co',
          function()
            vim.lsp.buf.code_action {
              apply = true,
              context = {
                only = { 'source.organizeImports' },
                diagnostics = {},
              },
            }
          end,
          desc = 'Organize Imports',
        },
      },
    },
  },
  format = {
    python = function(bufnr)
      if require('conform').get_formatter_info('ruff_format', bufnr).available then
        return { 'ruff_format' }
      else
        return { 'isort', 'black' }
      end
    end,
  },
  lint = {
    python = { 'mypy', 'ruff' },
  },
}
