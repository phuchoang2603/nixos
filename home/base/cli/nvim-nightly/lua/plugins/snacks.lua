vim.pack.add {
  'https://github.com/folke/snacks.nvim',
}

local Snacks = require 'snacks'

Snacks.setup {
  bigfile = { enabled = true },
  input = { enabled = true },
  layout = { enabled = true },
  notifier = { enabled = true },
  quickfile = { enabled = true },
  dim = { enabled = true },
  scope = { enabled = true },
  statuscolumn = { enabled = true },
  toggle = { enabled = true },
  indent = { enabled = true },
  words = { enabled = true },
  zen = { enabled = true },

  picker = {
    sources = {
      files = {
        hidden = true,
        ignored = true,
        win = {
          input = {
            keys = {
              ['<S-h>'] = 'toggle_hidden',
              ['<S-i>'] = 'toggle_ignored',
              ['<S-f>'] = 'toggle_follow',
            },
          },
        },
        exclude = {
          '**/.git/*',
          '**/node_modules/*',
          '**/.yarn/cache/*',
          '**/.yarn/install*',
          '**/.yarn/releases/*',
          '**/.pnpm-store/*',
          '**/.idea/*',
          '**/.DS_Store',
          'build/*',
          'coverage/*',
          'dist/*',
          'hodor-types/*',
          '**/target/*',
          '**/public/*',
          '**/digest*.txt',
          '**/.node-gyp/**',
        },
      },
      grep = {
        hidden = true,
        ignored = true,
        win = {
          input = {
            keys = {
              ['<S-h>'] = 'toggle_hidden',
              ['<S-i>'] = 'toggle_ignored',
              ['<S-f>'] = 'toggle_follow',
            },
          },
        },
        exclude = {
          '**/.git/*',
          '**/node_modules/*',
          '**/.yarn/cache/*',
          '**/.yarn/install*',
          '**/.yarn/releases/*',
          '**/.pnpm-store/*',
          '**/.venv/*',
          '**/.idea/*',
          '**/.DS_Store',
          '**/yarn.lock',
          'build*/*',
          'coverage/*',
          'dist/*',
          'certificates/*',
          'hodor-types/*',
          '**/target/*',
          '**/public/*',
          '**/digest*.txt',
          '**/.node-gyp/**',
        },
      },
      grep_buffers = {},
    },
  },
}

local keymaps = {
  { '<leader><space>', function() Snacks.picker.smart() end, desc = 'Smart Find Files' },
  { '<leader>/', function() Snacks.picker.grep() end, desc = 'Grep' },
  { '<leader>:', function() Snacks.picker.command_history() end, desc = 'Command History' },
  { '<leader>n', function() Snacks.picker.notifications() end, desc = 'Notification History' },
  -- buffers
  { '<leader>bd', function() Snacks.bufdelete() end, desc = 'Delete buffer', mode = { 'n' } },
  { '<leader>bo', function() Snacks.bufdelete.other() end, desc = 'Delete other buffers', mode = { 'n' } },
  {
    '<leader>,',
    function()
      Snacks.picker.buffers {
        win = {
          input = {
            keys = {
              ['dd'] = 'bufdelete',
              ['<c-d>'] = { 'bufdelete', mode = { 'n', 'i' } },
            },
          },
          list = { keys = { ['dd'] = 'bufdelete' } },
        },
      }
    end,
    desc = 'Buffers',
  },
  -- git
  { '<leader>gb', function() Snacks.picker.git_branches() end, desc = 'Git Branches' },
  { '<leader>gl', function() Snacks.picker.git_log() end, desc = 'Git Log' },
  { '<leader>gs', function() Snacks.picker.git_stash() end, desc = 'Git Stash' },
  { '<leader>gp', function() Snacks.picker.git_diff() end, desc = 'Git Diff Picker (Hunks)' },
  { '<leader>gf', function() Snacks.picker.git_log_file() end, desc = 'Git Log File' },
  { '<leader>gg', function() Snacks.lazygit() end, desc = 'Lazygit (Root Dir)' },
  -- search
  { '<leader>sw', function() Snacks.picker.grep_word() end, desc = 'Visual selection or word', mode = { 'n', 'x' } },
  { '<leader>s"', function() Snacks.picker.registers() end, desc = 'Registers' },
  { '<leader>s/', function() Snacks.picker.search_history() end, desc = 'Search History' },
  { '<leader>sa', function() Snacks.picker.autocmds() end, desc = 'Autocmds' },
  { '<leader>sb', function() Snacks.picker.lines() end, desc = 'Buffer Lines' },
  { '<leader>sd', function() Snacks.picker.diagnostics() end, desc = 'Diagnostics' },
  { '<leader>sj', function() Snacks.picker.jumps() end, desc = 'Jumps' },
  { '<leader>sk', function() Snacks.picker.keymaps() end, desc = 'Keymaps' },
  { '<leader>sl', function() Snacks.picker.loclist() end, desc = 'Location List' },
  { '<leader>sm', function() Snacks.picker.marks() end, desc = 'Marks' },
  { '<leader>sr', function() Snacks.picker.recent() end, desc = 'Recent' },
  { '<leader>su', function() Snacks.picker.undo() end, desc = 'Undo History' },
  -- LSP
  { 'gd', function() Snacks.picker.lsp_definitions() end, desc = 'Goto Definition' },
  { 'gD', function() Snacks.picker.lsp_declarations() end, desc = 'Goto Declaration' },
  { 'gr', function() Snacks.picker.lsp_references() end, nowait = true, desc = 'References' },
  { 'gI', function() Snacks.picker.lsp_implementations() end, desc = 'Goto Implementation' },
  { 'gy', function() Snacks.picker.lsp_type_definitions() end, desc = 'Goto Type Definition' },
  { '<leader>ss', function() Snacks.picker.lsp_symbols() end, desc = 'LSP Symbols' },
  { '<leader>sS', function() Snacks.picker.lsp_workspace_symbols() end, desc = 'LSP Workspace Symbols' },
  { '<leader>cR', function() Snacks.rename.rename_file() end, desc = 'Rename File' },
  { ']]', function() Snacks.words.jump(vim.v.count1) end, desc = 'Next Reference', mode = { 'n', 't' } },
  { '[[', function() Snacks.words.jump(-vim.v.count1) end, desc = 'Prev Reference', mode = { 'n', 't' } },
  {
    'gai',
    function() Snacks.picker.lsp_incoming_calls() end,
    desc = 'C[a]lls Incoming',
    has = 'callHierarchy/incomingCalls',
  },
  {
    'gao',
    function() Snacks.picker.lsp_outgoing_calls() end,
    desc = 'C[a]lls Outgoing',
    has = 'callHierarchy/outgoingCalls',
  },
  -- Snacks Toggles (UI)
  { '<leader>us', function() Snacks.toggle.option('spell', { name = 'Spelling' }):toggle() end, desc = 'Toggle Spelling' },
  { '<leader>uw', function() Snacks.toggle.option('wrap', { name = 'Wrap' }):toggle() end, desc = 'Toggle Wrap' },
  { '<leader>ud', function() Snacks.toggle.diagnostics():toggle() end, desc = 'Toggle Diagnostics' },
  { '<leader>ut', function() Snacks.toggle.treesitter():toggle() end, desc = 'Toggle Treesitter' },
  { '<leader>uz', function() Snacks.toggle.zen():toggle() end, desc = 'Toggle Zen Mode' },
}

for _, map in ipairs(keymaps) do
  local opts = { desc = map.desc }
  if map.silent ~= nil then opts.silent = map.silent end
  if map.noremap ~= nil then
    opts.noremap = map.noremap
  else
    opts.noremap = true
  end
  if map.expr ~= nil then opts.expr = map.expr end

  local mode = map.mode or 'n'
  vim.keymap.set(mode, map[1], map[2], opts)
end
