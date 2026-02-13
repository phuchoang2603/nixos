return {
  {
    'lervag/vimtex',
    lazy = false, -- we don't want to lazy load VimTeX
    init = function()
      vim.g.vimtex_view_method = 'zathura'
      vim.g.vimtex_view_general_viewer = 'zathura'
      vim.g.vimtex_mappings_prefix = '<leader>l'
    end,
    keys = {
      { '<leader>l', '', desc = '+vimtex', ft = 'tex' },
    },
  },
}
