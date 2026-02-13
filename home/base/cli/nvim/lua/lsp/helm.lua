-- Helm language configuration
local utils = require 'lsp.utils'

return {
  lsp = {
    helm_ls = {
      root_dir = utils.get_root_dir { 'Chart.yaml', '.git' },
    },
  },
  format = {},
  lint = {},
}
