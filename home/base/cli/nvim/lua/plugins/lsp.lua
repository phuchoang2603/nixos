return {
  'neovim/nvim-lspconfig',
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
  keys = {
    { '<leader>cl', '<cmd>LspInfo<cr>', desc = 'Lsp Info' },
  },
  config = function()
    -- Diagnostic configuration
    vim.diagnostic.config {
      update_in_insert = false,
      severity_sort = true,
      float = { border = 'rounded', source = 'if_many' },
      underline = { severity = vim.diagnostic.severity.ERROR },
      virtual_text = true,
      virtual_lines = false,
      jump = { float = true },
    }

    -- LSP keymaps on attach
    vim.api.nvim_create_autocmd('LspAttach', {
      group = vim.api.nvim_create_augroup('lsp-attach', { clear = true }),
      callback = function(event)
        local map = function(keys, func, desc, mode)
          mode = mode or 'n'
          vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
        end

        -- LSP keymaps - Goto actions
        map('gd', vim.lsp.buf.definition, '[G]oto [D]efinition')
        map('gr', vim.lsp.buf.references, '[G]oto [R]eferences')
        map('gI', vim.lsp.buf.implementation, '[G]oto [I]mplementation')
        map('gy', vim.lsp.buf.type_definition, '[G]oto T[y]pe Definition')
        map('gD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')

        -- Hover & Signature Help
        map('K', vim.lsp.buf.hover, 'Hover Documentation')
        map('gK', vim.lsp.buf.signature_help, 'Signature Help')
        map('<c-k>', vim.lsp.buf.signature_help, 'Signature Help', 'i')

        -- Code Actions
        map('<leader>ca', vim.lsp.buf.code_action, '[C]ode [A]ction', { 'n', 'x' })
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
          'Source [A]ction'
        )

        -- Rename
        map('<leader>cr', vim.lsp.buf.rename, '[C]ode [R]ename')

        -- Codelens
        local client = vim.lsp.get_client_by_id(event.data.client_id)
        if client and client:supports_method('textDocument/codeLens', event.buf) then
          map('<leader>cc', vim.lsp.codelens.run, 'Run [C]odelens', { 'n', 'x' })
          map('<leader>cC', vim.lsp.codelens.refresh, 'Refresh & Display [C]odelens')
        end

        -- Document highlight
        if client and client:supports_method('textDocument/documentHighlight', event.buf) then
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

          -- Reference navigation (when references are highlighted)
          map(']]', function() vim.cmd 'normal! ]]' end, 'Next Reference')
          map('[[', function() vim.cmd 'normal! [[' end, 'Prev Reference')
          map('<a-n>', function() vim.cmd 'normal! ]]' end, 'Next Reference')
          map('<a-p>', function() vim.cmd 'normal! [[' end, 'Prev Reference')
        end

        -- Inlay hints - enable by default and provide toggle
        if client and client:supports_method('textDocument/inlayHint', event.buf) then
          vim.lsp.inlay_hint.enable(true, { bufnr = event.buf })
          map('<leader>ch', function() vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf }) end, 'Code Toggle Inlay Hints')
        end
      end,
    })

    -- Get capabilities from blink.cmp
    local capabilities = require('blink.cmp').get_lsp_capabilities()

    -- Setup all language servers
    local servers = require('config.servers').get_servers()

    for server_name, server_config in pairs(servers) do
      server_config.capabilities = vim.tbl_deep_extend('force', {}, capabilities, server_config.capabilities or {})
      -- Enable LSP-based folding
      server_config.folds = {
        enabled = true,
      }
      vim.lsp.config(server_name, server_config)
      vim.lsp.enable(server_name)
    end
  end,
}
