return {
  'neovim/nvim-lspconfig',
  event = { 'BufReadPre', 'BufNewFile' },
  dependencies = {
    'saghen/blink.cmp',
    'b0o/schemastore.nvim',
  },
  opts = function()
    local ret = {
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
            [vim.diagnostic.severity.ERROR] = ' ',
            [vim.diagnostic.severity.WARN] = ' ',
            [vim.diagnostic.severity.HINT] = ' ',
            [vim.diagnostic.severity.INFO] = ' ',
          },
        },
        float = { border = 'rounded', source = 'if_many' },
        jump = { float = true },
      },

      -- Inlay hints configuration
      inlay_hints = {
        enabled = true,
        exclude = {},
      },

      -- Code lens configuration
      codelens = {
        enabled = true,
      },

      -- LSP Server Settings
      servers = {
        -- Global server configuration
        ['*'] = {
          capabilities = {
            workspace = {
              fileOperations = {
                didRename = true,
                willRename = true,
              },
            },
          },
          keys = {
            { 'gd', vim.lsp.buf.definition, desc = 'Goto Definition' },
            { 'gr', vim.lsp.buf.references, desc = 'References' },
            { 'gI', vim.lsp.buf.implementation, desc = 'Goto Implementation' },
            { 'gy', vim.lsp.buf.type_definition, desc = 'Goto T[y]pe Definition' },
            { 'gD', vim.lsp.buf.declaration, desc = 'Goto Declaration' },
            { 'K', vim.lsp.buf.hover, desc = 'Hover' },
            { 'gK', vim.lsp.buf.signature_help, desc = 'Signature Help' },
            { '<c-k>', vim.lsp.buf.signature_help, mode = 'i', desc = 'Signature Help' },
            { '<leader>ca', vim.lsp.buf.code_action, mode = { 'n', 'x' }, desc = 'Code Action' },
            { '<leader>cc', vim.lsp.codelens.run, mode = { 'n', 'x' }, desc = 'Run Codelens' },
            { '<leader>cC', vim.lsp.codelens.refresh, mode = 'n', desc = 'Refresh & Display Codelens' },
            { '<leader>cr', vim.lsp.buf.rename, desc = 'Rename' },
            {
              '<leader>cA',
              function()
                vim.lsp.buf.code_action {
                  context = {
                    only = { 'source' },
                    diagnostics = {},
                  },
                }
              end,
              desc = 'Source Action',
            },
            { ']]', function() Snacks.words.jump(vim.v.count1) end, desc = 'Next Reference' },
            { '[[', function() Snacks.words.jump(-vim.v.count1) end, desc = 'Prev Reference' },
            { '<a-n>', function() Snacks.words.jump(vim.v.count1, true) end, desc = 'Next Reference' },
            { '<a-p>', function() Snacks.words.jump(-vim.v.count1, true) end, desc = 'Prev Reference' },
            { '<leader>cl', function() Snacks.picker.lsp_config() end, desc = 'LSP Info' },
            { '<leader>ch', function() vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = 0 }) end, desc = 'Toggle Inlay Hints' },
          },
        },
      },

      -- Server-specific setup hooks
      setup = {
        -- Workaround for gopls semantic tokens performance issue
        gopls = function(_, opts)
          -- Disable semantic tokens due to performance issues
          -- https://github.com/golang/go/issues/54531#issuecomment-1464982242
          opts.capabilities = vim.tbl_deep_extend('force', opts.capabilities or {}, {
            semanticTokensProvider = nil,
          })
          return false -- Continue with default setup
        end,
      },
    }

    -- Load servers from config.servers
    local servers = require('config.servers').get_servers()
    for server_name, server_config in pairs(servers) do
      ret.servers[server_name] = server_config
    end

    return ret
  end,

  config = function(_, opts)
    local blink_capabilities = require('blink.cmp').get_lsp_capabilities()

    -- Inlay hints
    if opts.inlay_hints.enabled then
      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('lsp-inlay-hints', { clear = true }),
        callback = function(args)
          local client = vim.lsp.get_client_by_id(args.data.client_id)
          if client and client:supports_method 'textDocument/inlayHint' then
            local bufnr = args.buf
            if vim.api.nvim_buf_is_valid(bufnr) and vim.bo[bufnr].buftype == '' and not vim.tbl_contains(opts.inlay_hints.exclude, vim.bo[bufnr].filetype) then
              vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
            end
          end
        end,
      })
    end

    -- Code lens
    if opts.codelens.enabled and vim.lsp.codelens then
      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('lsp-codelens', { clear = true }),
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

    -- Document highlight
    vim.api.nvim_create_autocmd('LspAttach', {
      group = vim.api.nvim_create_augroup('lsp-document-highlight', { clear = true }),
      callback = function(args)
        local client = vim.lsp.get_client_by_id(args.data.client_id)
        if client and client:supports_method 'textDocument/documentHighlight' then
          local highlight_augroup = vim.api.nvim_create_augroup('lsp-highlight', { clear = false })
          vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
            buffer = args.buf,
            group = highlight_augroup,
            callback = vim.lsp.buf.document_highlight,
          })

          vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
            buffer = args.buf,
            group = highlight_augroup,
            callback = vim.lsp.buf.clear_references,
          })

          vim.api.nvim_create_autocmd('LspDetach', {
            group = vim.api.nvim_create_augroup('lsp-detach', { clear = true }),
            callback = function(event2)
              vim.lsp.buf.clear_references()
              vim.api.nvim_clear_autocmds { group = 'lsp-highlight', buffer = event2.buf }
            end,
          })
        end
      end,
    })

    -- Setup keymaps on attach
    vim.api.nvim_create_autocmd('LspAttach', {
      group = vim.api.nvim_create_augroup('lsp-keymaps', { clear = true }),
      callback = function(args)
        local client = vim.lsp.get_client_by_id(args.data.client_id)
        local buffer = args.buf

        -- Get server-specific keys or global keys
        local server_name = client and client.name or nil
        local keys = opts.servers[server_name] and opts.servers[server_name].keys or opts.servers['*'].keys

        for _, key in ipairs(keys) do
          local modes = type(key.mode) == 'table' and key.mode or { key.mode or 'n' }
          local has_capability = not key.has or (client and client:supports_method(key.has))

          if has_capability then
            vim.keymap.set(modes, key[1], key[2], {
              buffer = buffer,
              desc = key.desc,
              silent = key.silent ~= false,
            })
          end
        end
      end,
    })

    -- Diagnostics
    vim.diagnostic.config(vim.deepcopy(opts.diagnostics))

    -- Configure global server options
    if opts.servers['*'] then vim.lsp.config('*', opts.servers['*']) end

    -- Configure and enable all servers
    local function configure(server)
      if server == '*' then return false end

      local sopts = opts.servers[server]
      if not sopts or sopts.enabled == false then return end

      -- Merge capabilities from blink.cmp
      sopts.capabilities = vim.tbl_deep_extend('force', {}, blink_capabilities, sopts.capabilities or {})

      -- Run custom setup if exists
      local setup = opts.setup[server] or opts.setup['*']
      if setup and setup(server, sopts) then return end

      -- Configure and enable the server
      vim.lsp.config(server, sopts)
      vim.lsp.enable(server)
    end

    for server in pairs(opts.servers) do
      configure(server)
    end
  end,
}
