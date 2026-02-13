return {
  {
    'RRethy/base16-nvim',
    lazy = false,
    priority = 1000,
    config = function()
      -- Read Stylix-generated colors
      local palette_path = vim.fn.expand '~/.config/stylix/palette.json'
      local file = io.open(palette_path, 'r')

      if file then
        local content = file:read '*a'
        file:close()

        local ok, palette = pcall(vim.json.decode, content)
        if ok and palette then
          -- Apply base16 colors from Stylix palette
          require('base16-colorscheme').setup {
            base00 = '#' .. palette.base00,
            base01 = '#' .. palette.base01,
            base02 = '#' .. palette.base02,
            base03 = '#' .. palette.base03,
            base04 = '#' .. palette.base04,
            base05 = '#' .. palette.base05,
            base06 = '#' .. palette.base06,
            base07 = '#' .. palette.base07,
            base08 = '#' .. palette.base08,
            base09 = '#' .. palette.base09,
            base0A = '#' .. palette.base0A,
            base0B = '#' .. palette.base0B,
            base0C = '#' .. palette.base0C,
            base0D = '#' .. palette.base0D,
            base0E = '#' .. palette.base0E,
            base0F = '#' .. palette.base0F,
          }
        else
          vim.notify('Failed to parse Stylix palette.json', vim.log.levels.WARN)
          vim.cmd.colorscheme 'base16-default-dark'
        end
      else
        vim.notify('Stylix palette.json not found, using default theme', vim.log.levels.WARN)
        vim.cmd.colorscheme 'base16-default-dark'
      end
    end,
  },
}
