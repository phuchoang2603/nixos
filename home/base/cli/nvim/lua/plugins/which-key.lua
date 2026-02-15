return {
  'folke/which-key.nvim',
  event = 'VimEnter',
  opts = {
    preset = 'helix',
    delay = 0,
    win = {
      border = 'rounded',
    },
    icons = {
      breadcrumb = '»',
      separator = '➜',
      group = '+',
      mappings = vim.g.have_nerd_font,
    },

    spec = {
      { '<leader>b', group = 'Buffer' },
      { '<leader>c', group = 'Code' },
      { '<leader>g', group = 'Git' },
      { '<leader>s', group = 'Search', mode = { 'n', 'v' } },
      { '<leader>t', group = 'Toggle' },
      { '<leader>o', group = 'Opencode' },
      { '<leader>x', group = 'Diagnostics/Quickfi[x]' },
      { '<leader>h', group = 'Git [H]unk', mode = { 'n', 'v' } },
    },
  },
}
