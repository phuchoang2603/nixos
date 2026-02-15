-- LSP Configuration
-- Loads language-specific LSP configurations from lua/config/lsp-configs.lua

-- Load all language configurations from the central config file
local lang_configs = require 'lsp.lsp-configs'

-- Extract LSP servers and plugins from language configs
local servers = {}
local plugins = {}

for _, config in pairs(lang_configs) do
  if config.lsp then servers = vim.tbl_deep_extend('force', servers, config.lsp) end
  if config.plugins then vim.list_extend(plugins, config.plugins) end
end

-- Build the plugin spec
local spec = {
  {
    'neovim/nvim-lspconfig',
    event = { 'BufReadPre', 'BufNewFile' },
    dependencies = {
      'b0o/schemastore.nvim', -- JSON/YAML schemas
    },
    opts = function()
      return {
        -- Diagnostic configuration
        diagnostics = {
          underline = true,
          update_in_insert = false,
          virtual_text = {
            spacing = 4,
            source = 'if_many',
            prefix = '●',
          },
          severity_sort = true,
          signs = {
            text = {
              [vim.diagnostic.severity.ERROR] = 'E',
              [vim.diagnostic.severity.WARN] = 'W',
              [vim.diagnostic.severity.HINT] = 'H',
              [vim.diagnostic.severity.INFO] = 'I',
            },
          },
        },
        -- Inlay hints configuration
        inlay_hints = {
          enabled = true,
        },
        -- Code lens configuration
        codelens = {
          enabled = false,
        },
        -- Folding configuration
        folds = {
          enabled = true,
        },
        -- Format configuration
        format = {
          formatting_options = nil,
          timeout_ms = nil,
        },
        -- LSP Server configurations (loaded from language files)
        servers = vim.tbl_deep_extend('force', {
          -- Default configuration for all servers
          ['*'] = {
            capabilities = {
              workspace = {
                fileOperations = {
                  didRename = true,
                  willRename = true,
                },
              },
            },
            -- stylua: ignore
            keys = {
              { '<leader>cl', function() Snacks.picker.lsp_config() end, desc = 'Lsp Info' },
              { 'gd', function() Snacks.picker.lsp_definitions() end, desc = 'Goto Definition', has = 'definition' },
              { 'gr', function() Snacks.picker.lsp_references() end, desc = 'References', nowait = true },
              { 'gI', function() Snacks.picker.lsp_implementations() end, desc = 'Goto Implementation' },
              { 'gy', function() Snacks.picker.lsp_type_definitions() end, desc = 'Goto Type Definition' },
              { "gD", function() Snacks.picker.lsp_declarations() end, desc = "Goto Declaration" },
              { 'K', function() return vim.lsp.buf.hover() end, desc = 'Hover' },
              { 'gK', function() return vim.lsp.buf.signature_help() end, desc = 'Signature Help', has = 'signatureHelp' },
              { '<c-k>', function() return vim.lsp.buf.signature_help() end, mode = 'i', desc = 'Signature Help', has = 'signatureHelp' },
              { '<leader>ca', vim.lsp.buf.code_action, desc = 'Code Action', mode = { 'n', 'x' }, has = 'codeAction' },
              { '<leader>cc', vim.lsp.codelens.run, desc = 'Run Codelens', mode = { 'n', 'x' }, has = 'codeLens' },
              { '<leader>cC', vim.lsp.codelens.refresh, desc = 'Refresh & Display Codelens', mode = { 'n' }, has = 'codeLens' },
              { '<leader>cR', function() Snacks.rename.rename_file() end, desc = 'Rename File', mode = { 'n' }, has = { 'workspace/didRenameFiles', 'workspace/willRenameFiles' } },
              { '<leader>cr', vim.lsp.buf.rename, desc = 'Rename', has = 'rename' },
              { ']]', function() Snacks.words.jump(vim.v.count1) end, has = 'documentHighlight', desc = 'Next Reference', enabled = function() return Snacks.words.is_enabled() end },
              { '[[', function() Snacks.words.jump(-vim.v.count1) end, has = 'documentHighlight', desc = 'Prev Reference', enabled = function() return Snacks.words.is_enabled() end },
              { '<a-n>', function() Snacks.words.jump(vim.v.count1, true) end, has = 'documentHighlight', desc = 'Next Reference', enabled = function() return Snacks.words.is_enabled() end },
              { '<a-p>', function() Snacks.words.jump(-vim.v.count1, true) end, has = 'documentHighlight', desc = 'Prev Reference', enabled = function() return Snacks.words.is_enabled() end },
            },
          },
        }, servers),
        -- Custom setup hooks
        setup = {},
      }
    end,
    config = function(_, opts)
      -- Setup keymaps for each server
      for server, server_opts in pairs(opts.servers) do
        if type(server_opts) == 'table' and server_opts.keys then
          local LazyKeys = require 'lazy.core.handler.keys'
          local keymaps = {}
          for _, keymap in ipairs(server_opts.keys) do
            keymaps[#keymaps + 1] = LazyKeys.parse(keymap)
          end

          vim.api.nvim_create_autocmd('LspAttach', {
            callback = function(args)
              local client = vim.lsp.get_client_by_id(args.data.client_id)
              if not client then return end
              if server ~= '*' and client.name ~= server then return end

              for _, keys in pairs(keymaps) do
                local has = not keys.has
                if not has then
                  if type(keys.has) == 'table' then
                    has = vim.tbl_contains(vim.tbl_map(function(m) return client:supports_method(m) end, keys.has), true)
                  else
                    has = client:supports_method('textDocument/' .. keys.has)
                  end
                end
                if has and keys.enabled ~= false then
                  local opts_key = {
                    buffer = args.buf,
                    desc = keys.desc,
                  }
                  vim.keymap.set(keys.mode or 'n', keys.lhs, keys.rhs, opts_key)
                end
              end
            end,
          })
        end
      end

      -- Setup inlay hints
      if opts.inlay_hints.enabled then
        vim.api.nvim_create_autocmd('LspAttach', {
          callback = function(args)
            local client = vim.lsp.get_client_by_id(args.data.client_id)
            if client and client:supports_method 'textDocument/inlayHint' then
              if vim.api.nvim_buf_is_valid(args.buf) and vim.bo[args.buf].buftype == '' then vim.lsp.inlay_hint.enable(true, { bufnr = args.buf }) end
            end
          end,
        })
      end

      -- Setup folding
      if opts.folds.enabled then
        vim.api.nvim_create_autocmd('LspAttach', {
          callback = function(args)
            local client = vim.lsp.get_client_by_id(args.data.client_id)
            if client and client:supports_method 'textDocument/foldingRange' then
              vim.wo[0].foldmethod = 'expr'
              vim.wo[0].foldexpr = 'v:lua.vim.lsp.foldexpr()'
            end
          end,
        })
      end

      -- Setup code lens
      if opts.codelens.enabled and vim.lsp.codelens then
        vim.api.nvim_create_autocmd('LspAttach', {
          callback = function(args)
            local client = vim.lsp.get_client_by_id(args.data.client_id)
            if client and client:supports_method 'textDocument/codeLens' then
              vim.lsp.codelens.refresh()
              vim.api.nvim_create_autocmd({ 'BufEnter', 'CursorHold', 'InsertLeave' }, {
                buffer = args.buf,
                callback = vim.lsp.codelens.refresh,
              })
            end
          end,
        })
      end

      -- Configure diagnostics
      vim.diagnostic.config(vim.deepcopy(opts.diagnostics))

      -- Configure global LSP settings
      if opts.servers['*'] then vim.lsp.config('*', opts.servers['*']) end

      -- Configure and enable each LSP server
      for server, server_opts in pairs(opts.servers) do
        if server ~= '*' then
          local sopts = server_opts == true and {} or (not server_opts) and { enabled = false } or server_opts

          -- Run custom setup if exists
          local setup = opts.setup[server] or opts.setup['*']
          if not setup or not setup(server, sopts) then
            vim.lsp.config(server, sopts)
            vim.lsp.enable(server)
          end
        end
      end
    end,
  },
}

-- Add collected plugins from language files
for _, plugin in ipairs(plugins) do
  table.insert(spec, plugin)
end

return spec
