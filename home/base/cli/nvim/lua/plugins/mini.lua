return {
  'nvim-mini/mini.nvim',
  config = function()
    -- Add/delete/replace surroundings (brackets, quotes, etc.)
    require('mini.surround').setup()

    -- Auto pairs
    require('mini.pairs').setup()
  end,
}
