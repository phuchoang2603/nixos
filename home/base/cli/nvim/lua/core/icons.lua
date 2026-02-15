local M = {}

-- Helper to get icons from mini.icons with fallbacks
local function get_icon(category, name, fallback)
  if _G.MiniIcons then
    local icon, _, _ = MiniIcons.get(category, name)
    return icon and (icon .. ' ') or fallback
  end
  return fallback
end

-- Diagnostics (mini.icons does NOT have a 'diagnostic' category. It uses 'filetype' or 'extension' patterns)
-- We use fixed glyphs here for consistency in the LSP system.
M.diagnostics = {
  Error = '󰅚 ',
  Warn = '󰀪 ',
  Hint = '󰌶 ',
  Info = '󰋽 ',
}

-- Git
M.git = {
  added = ' ',
  modified = ' ',
  removed = ' ',
}

return M
