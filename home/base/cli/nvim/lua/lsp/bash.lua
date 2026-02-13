-- Bash/Shell language configuration
local utils = require 'lsp.utils'

return {
  lsp = {
    bashls = {
      root_dir = utils.get_root_dir { '.git' },
    },
  },
  format = {
    sh = { 'shfmt' },
    bash = { 'shfmt' },
  },
  lint = {},
}
