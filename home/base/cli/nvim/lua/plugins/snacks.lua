return {
  'folke/snacks.nvim',
  priority = 1000,
  lazy = false,
  opts = {
    scroll = {
      enabled = false,
    },
    dashboard = {
      sections = {
        { section = 'header' },
        { section = 'keys', padding = 1 },
        { section = 'recent_files', padding = 1 },
        { section = 'startup' },
      },
    },
    explorer = {
      enabled = false,
    },
    -- Enable better UI for vim.ui.select and vim.ui.input
    input = {
      enabled = true,
    },
    -- Better code action and other select menus
    picker = {
      enabled = true,
    },
  },

  keys = {
    -- Top Level
    { '<leader>,', function() Snacks.picker.buffers() end, desc = 'Buffers' },
    { '<leader>/', function() Snacks.picker.grep() end, desc = 'Grep (Root Dir)' },
    { '<leader>:', function() Snacks.picker.command_history() end, desc = 'Command History' },
    { '<leader><space>', function() Snacks.picker.files() end, desc = 'Find Files (Root Dir)' },
    { '<leader>n', function() Snacks.picker.notifications() end, desc = 'Notification History' },
    -- Search
    { '<leader>s"', function() Snacks.picker.registers() end, desc = 'Registers' },
    { '<leader>sd', function() Snacks.picker.diagnostics() end, desc = 'Diagnostics' },
    { '<leader>sh', function() Snacks.picker.help() end, desc = 'Help Pages' },
    { '<leader>sk', function() Snacks.picker.keymaps() end, desc = 'Keymaps' },
    { '<leader>sq', function() Snacks.picker.qflist() end, desc = 'Quickfix List' },
    { '<leader>ss', function() Snacks.picker.lsp_symbols() end, desc = 'LSP Symbols' },
    { '<leader>sS', function() Snacks.picker.lsp_workspace_symbols() end, desc = 'LSP Workspace Symbols' },
    { '<leader>su', function() Snacks.picker.undo() end, desc = 'Undotree' },
    { '<leader>e', false },
    { '<leader>E', false },
  },
}
