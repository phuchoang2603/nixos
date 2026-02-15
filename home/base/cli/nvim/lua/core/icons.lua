local M = {}

-- Helper to get icons from mini.icons with fallbacks
local function get_icon(category, name, fallback)
  if _G.MiniIcons then
    local icon, _, _ = MiniIcons.get(category, name)
    return icon and (icon .. ' ') or fallback
  end
  return fallback
end

-- Diagnostics
M.diagnostics = {
  Error = get_icon('diagnostic', 'error', '󰅚 '),
  Warn  = get_icon('diagnostic', 'warn', '󰀪 '),
  Hint  = get_icon('diagnostic', 'hint', '󰌶 '),
  Info  = get_icon('diagnostic', 'info', '󰋽 '),
}

-- Git
M.git = {
  added    = get_icon('git', 'add', ' '),
  modified = get_icon('git', 'change', ' '),
  removed  = get_icon('git', 'delete', ' '),
}

-- LSP Kinds (for completion and symbols)
M.kinds = setmetatable({}, {
  __index = function(_, key)
    return get_icon('lsp', key, '')
  end,
})

return M
