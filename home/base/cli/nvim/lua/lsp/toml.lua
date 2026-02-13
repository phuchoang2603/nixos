-- TOML language configuration
local utils = require 'lsp.utils'

return {
  lsp = {
    taplo = {
      root_dir = utils.get_root_dir { '.git' },
      keys = {
        {
          'K',
          function()
            if vim.fn.expand '%:t' == 'Cargo.toml' and require('crates').popup_available() then
              require('crates').show_popup()
            else
              vim.lsp.buf.hover()
            end
          end,
          desc = 'Show Crate Documentation',
        },
      },
    },
  },
  format = {
    toml = { 'taplo' },
  },
  lint = {},
}
