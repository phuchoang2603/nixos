-- Shared utilities for LSP configuration
local M = {}

-- Helper function for root directory detection
-- Usage: root_dir = get_root_dir { '.git', 'package.json' }
function M.get_root_dir(patterns)
  return function(fname)
    return vim.fs.root(fname, patterns)
  end
end

return M
