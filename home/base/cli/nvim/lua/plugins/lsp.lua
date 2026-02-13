return {
  'neovim/nvim-lspconfig',
  event = 'BufReadPre',
  dependencies = {
    -- Useful status updates for LSP.
    { 'j-hui/fidget.nvim', opts = {} },

    -- Allows extra capabilities provided by blink.cmp
    'saghen/blink.cmp',

    -- JSON/YAML schemas
    'b0o/schemastore.nvim',

    -- C/C++ extensions for clangd
    {
      'p00f/clangd_extensions.nvim',
      ft = { 'c', 'cpp', 'objc', 'objcpp', 'cuda' },
      opts = {
        inlay_hints = {
          inline = false,
        },
        ast = {
          role_icons = {
            type = '',
            declaration = '',
            expression = '',
            specifier = '',
            statement = '',
            ['template argument'] = '',
          },
          kind_icons = {
            Compound = '',
            Recovery = '',
            TranslationUnit = '',
            PackExpansion = '',
            TemplateTypeParm = '',
            TemplateTemplateParm = '',
            TemplateParamObject = '',
          },
        },
      },
    },

    -- Helm Language Server
    {
      'towolf/vim-helm',
      ft = 'helm',
    },
  },
  ---@class PluginLspOpts
  opts = function()
    local ret = {
      -- options for vim.diagnostic.config()
      ---@type vim.diagnostic.Opts
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
      },
      -- Enable this to enable the builtin LSP inlay hints on Neovim.
      inlay_hints = {
        enabled = true,
        exclude = { 'vue' }, -- filetypes for which you don't want to enable inlay hints
      },
      -- Enable this to enable the builtin LSP code lenses on Neovim.
      codelens = {
        enabled = false,
      },
      -- Enable this to enable the builtin LSP folding on Neovim.
      folds = {
        enabled = true,
      },
      -- LSP Server Settings
      ---@type table<string, vim.lsp.Config>
      servers = {},
      -- you can do any additional lsp server setup here
      -- return true if you don't want this server to be setup with lspconfig
      ---@type table<string, fun(server:string, opts: vim.lsp.Config):boolean?>
      setup = {},
    }
    return ret
  end,
  ---@param opts PluginLspOpts
  config = function(_, opts)
    -- Diagnostic icons
    local signs = {
      Error = ' ',
      Warn = ' ',
      Hint = ' ',
      Info = ' ',
    }
    for type, icon in pairs(signs) do
      local hl = 'DiagnosticSign' .. type
      vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = '' })
    end

    -- Diagnostics configuration
    vim.diagnostic.config(vim.deepcopy(opts.diagnostics))

    -- Setup keymaps on LSP attach
    vim.api.nvim_create_autocmd('LspAttach', {
      group = vim.api.nvim_create_augroup('lsp-attach', { clear = true }),
      callback = function(event)
        local map = function(keys, func, desc, mode)
          mode = mode or 'n'
          vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
        end

        -- LSP keymaps - Goto actions
        map('gd', vim.lsp.buf.definition, 'Goto Definition')
        map('gr', vim.lsp.buf.references, 'References')
        map('gI', vim.lsp.buf.implementation, 'Goto Implementation')
        map('gy', vim.lsp.buf.type_definition, 'Goto T[y]pe Definition')
        map('gD', vim.lsp.buf.declaration, 'Goto Declaration')

        -- Hover & Signature Help
        map('K', vim.lsp.buf.hover, 'Hover Documentation')
        map('gK', vim.lsp.buf.signature_help, 'Signature Help')
        map('<c-k>', vim.lsp.buf.signature_help, 'Signature Help', 'i')

        -- Code Actions
        map('<leader>ca', vim.lsp.buf.code_action, 'Code Action', { 'n', 'x' })
        map(
          '<leader>cA',
          function()
            vim.lsp.buf.code_action {
              context = {
                only = { 'source' },
                diagnostics = {},
              },
            }
          end,
          'Source Action'
        )

        -- Rename
        map('<leader>cr', vim.lsp.buf.rename, 'Rename')

        -- LSP Info
        map('<leader>cl', '<cmd>LspInfo<cr>', 'Lsp Info')

        -- Codelens
        local client = vim.lsp.get_client_by_id(event.data.client_id)
        if client and client:supports_method 'textDocument/codeLens' then
          map('<leader>cc', vim.lsp.codelens.run, 'Run Codelens', { 'n', 'x' })
          map('<leader>cC', vim.lsp.codelens.refresh, 'Refresh & Display Codelens')

          if opts.codelens.enabled then
            vim.lsp.codelens.refresh()
            vim.api.nvim_create_autocmd({ 'BufEnter', 'CursorHold', 'InsertLeave' }, {
              buffer = event.buf,
              callback = vim.lsp.codelens.refresh,
            })
          end
        end

        -- Document highlight with Snacks word navigation
        if client and client:supports_method 'textDocument/documentHighlight' then
          local highlight_augroup = vim.api.nvim_create_augroup('lsp-highlight', { clear = false })
          vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
            buffer = event.buf,
            group = highlight_augroup,
            callback = vim.lsp.buf.document_highlight,
          })

          vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
            buffer = event.buf,
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

          -- Reference navigation using Snacks.words if available
          local has_snacks, snacks = pcall(require, 'snacks')
          if has_snacks and snacks.words then
            map(']]', function() snacks.words.jump(vim.v.count1) end, 'Next Reference')
            map('[[', function() snacks.words.jump(-vim.v.count1) end, 'Prev Reference')
            map('<a-n>', function() snacks.words.jump(vim.v.count1, true) end, 'Next Reference')
            map('<a-p>', function() snacks.words.jump(-vim.v.count1, true) end, 'Prev Reference')
          else
            map(']]', function() vim.cmd 'normal! ]]' end, 'Next Reference')
            map('[[', function() vim.cmd 'normal! [[' end, 'Prev Reference')
          end
        end

        -- Inlay hints
        if client and client:supports_method 'textDocument/inlayHint' then
          if opts.inlay_hints.enabled and not vim.tbl_contains(opts.inlay_hints.exclude or {}, vim.bo[event.buf].filetype) then
            vim.lsp.inlay_hint.enable(true, { bufnr = event.buf })
          end
          map('<leader>ch', function()
            vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf }, { bufnr = event.buf })
          end, 'Toggle Inlay Hints')
        end
      end,
    })

    -- Setup folding
    if opts.folds.enabled then
      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('lsp-folds', { clear = true }),
        callback = function(event)
          local client = vim.lsp.get_client_by_id(event.data.client_id)
          if client and client:supports_method 'textDocument/foldingRange' then
            vim.wo[event.win].foldmethod = 'expr'
            vim.wo[event.win].foldexpr = 'v:lua.vim.lsp.foldexpr()'
          end
        end,
      })
    end

    -- Get capabilities from blink.cmp
    local capabilities = require('blink.cmp').get_lsp_capabilities()

    -- Add file operation capabilities
    capabilities = vim.tbl_deep_extend('force', capabilities, {
      workspace = {
        fileOperations = {
          didRename = true,
          willRename = true,
        },
      },
    })

    -- Load servers from config.servers
    local servers = require('config.servers').get_servers()

    -- Merge with opts.servers
    servers = vim.tbl_deep_extend('force', servers, opts.servers)

    -- Configure each server
    for server_name, server_config in pairs(servers) do
      if server_config.enabled ~= false then
        -- Merge capabilities
        server_config.capabilities = vim.tbl_deep_extend('force', {}, capabilities, server_config.capabilities or {})

        -- Enable folding
        if opts.folds.enabled then
          server_config.folds = { enabled = true }
        end

        -- Run custom setup if provided
        local setup = opts.setup[server_name] or opts.setup['*']
        if setup and setup(server_name, server_config) then
          -- setup returned true, skip default setup
        else
          vim.lsp.config(server_name, server_config)
          vim.lsp.enable(server_name)
        end
      end
    end
  end,
}
