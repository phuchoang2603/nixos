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
  Error = "󰅚 ",
  Warn  = "󰀪 ",
  Hint  = "󰌶 ",
  Info  = "󰋽 ",
}

-- Git
M.git = {
  added    = get_icon('git', 'add', ' '),
  modified = get_icon('git', 'change', ' '),
  removed  = get_icon('git', 'delete', ' '),
}

-- LSP Kinds (mini.icons uses 'lsp' category for these)
M.kinds = setmetatable({}, {
  __index = function(_, key)
    return get_icon('lsp', key, '')
  end,
})

return M
