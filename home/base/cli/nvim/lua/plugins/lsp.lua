return {
  'neovim/nvim-lspconfig',
  dependencies = {
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

        -- Codelens
        local client = vim.lsp.get_client_by_id(event.data.client_id)
        if client and client:supports_method('textDocument/codeLens', event.buf) then
          map('<leader>cc', vim.lsp.codelens.run, 'Run Codelens', { 'n', 'x' })
          map('<leader>cC', vim.lsp.codelens.refresh, 'Refresh & Display Codelens')
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
            map('<a-n>', function() vim.cmd 'normal! ]]' end, 'Next Reference')
            map('<a-p>', function() vim.cmd 'normal! [[' end, 'Prev Reference')
          end
        end

        -- Inlay hints - enable by default and provide toggle
        if client and client:supports_method('textDocument/inlayHint', event.buf) then
          vim.lsp.inlay_hint.enable(true, { bufnr = event.buf })
          map(
            '<leader>ch',
            function() vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf }, { bufnr = event.buf }) end,
            'Toggle Inlay Hints'
          )
        end
      end,
    })

    -- Get capabilities from blink.cmp
    local capabilities = require('blink.cmp').get_lsp_capabilities()

    -- Setup all language servers
    local servers = require('config.servers').get_servers()

    for server_name, server_config in pairs(servers) do
      server_config.capabilities = vim.tbl_deep_extend('force', {}, capabilities, server_config.capabilities or {})
      vim.lsp.config(server_name, server_config)
      vim.lsp.enable(server_name)
    end
  end,
}
