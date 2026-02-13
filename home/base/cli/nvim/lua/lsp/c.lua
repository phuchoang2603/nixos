-- C/C++ language configuration
local utils = require 'lsp.utils'

return {
  lsp = {
    clangd = {
      root_dir = utils.get_root_dir {
        '.clangd',
        '.clang-tidy',
        '.clang-format',
        'compile_commands.json',
        'compile_flags.txt',
        'configure.ac',
        '.git',
      },
      cmd = {
        'clangd',
        '--background-index',
        '--clang-tidy',
        '--header-insertion=iwyu',
        '--completion-style=detailed',
        '--function-arg-placeholders',
        '--fallback-style=llvm',
      },
    },
  },
  format = {},
  lint = {},
}
