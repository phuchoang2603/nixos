-- Central place to configure all LSP servers
local M = {}

-- Helper function for root directory detection
local function get_root_dir(patterns)
  return function(fname) return vim.fs.root(fname, patterns) end
end

function M.get_servers()
  return {
    -- Lua
    lua_ls = {
      root_dir = get_root_dir { '.luarc.json', '.luarc.jsonc', '.luacheckrc', '.stylua.toml', 'stylua.toml', 'selene.toml', 'selene.yml', '.git' },
      settings = {
        Lua = {
          workspace = {
            checkThirdParty = false,
          },
          codeLens = {
            enable = true,
          },
          completion = {
            callSnippet = 'Replace',
          },
          doc = {
            privateName = { '^_' },
          },
          hint = {
            enable = true,
            setType = false,
            paramType = true,
            paramName = 'Disable',
            semicolon = 'Disable',
            arrayIndex = 'Disable',
          },
        },
      },
    },

    -- C/C++
    clangd = {
      root_dir = get_root_dir { '.clangd', '.clang-tidy', '.clang-format', 'compile_commands.json', 'compile_flags.txt', 'configure.ac', '.git' },
      cmd = {
        'clangd',
        '--background-index',
        '--clang-tidy',
        '--header-insertion=iwyu',
        '--completion-style=detailed',
        '--function-arg-placeholders',
        '--fallback-style=llvm',
      },
    },

    -- Go
    gopls = {
      root_dir = get_root_dir { 'go.work', 'go.mod', '.git' },
      settings = {
        gopls = {
          gofumpt = true,
          codelenses = {
            gc_details = false,
            generate = true,
            regenerate_cgo = true,
            run_govulncheck = true,
            test = true,
            tidy = true,
            upgrade_dependency = true,
            vendor = true,
          },
          hints = {
            assignVariableTypes = true,
            compositeLiteralFields = true,
            compositeLiteralTypes = true,
            constantValues = true,
            functionTypeParameters = true,
            parameterNames = true,
            rangeVariableTypes = true,
          },
          analyses = {
            nilness = true,
            unusedparams = true,
            unusedwrite = true,
            useany = true,
          },
          usePlaceholders = true,
          completeUnimported = true,
          staticcheck = true,
          directoryFilters = { '-.git', '-.vscode', '-.idea', '-.vscode-test', '-node_modules' },
          -- semanticTokens disabled in setup hook due to performance issues
        },
      },
    },

    -- Python
    basedpyright = {
      root_dir = get_root_dir { 'pyproject.toml', 'setup.py', 'setup.cfg', 'requirements.txt', 'Pipfile', 'pyrightconfig.json', '.git' },
      settings = {
        basedpyright = {
          analysis = {
            typeCheckingMode = 'standard',
            autoSearchPaths = true,
            diagnosticMode = 'openFilesOnly',
            useLibraryCodeForTypes = true,
            diagnosticSeverityOverrides = {
              reportUnusedVariable = 'warning',
              reportUnusedImport = 'warning',
            },
          },
        },
      },
    },
    ruff = {
      cmd_env = { RUFF_TRACE = 'messages' },
      init_options = {
        settings = {
          logLevel = 'error',
        },
      },
      keys = {
        {
          '<leader>co',
          function()
            vim.lsp.buf.code_action {
              apply = true,
              context = {
                only = { 'source.organizeImports' },
                diagnostics = {},
              },
            }
          end,
          desc = 'Organize Imports',
        },
      },
    },

    -- YAML
    yamlls = {
      root_dir = get_root_dir { '.git' },
      capabilities = {
        textDocument = {
          foldingRange = {
            dynamicRegistration = false,
            lineFoldingOnly = true,
          },
        },
      },
      on_new_config = function(new_config)
        new_config.settings.yaml.schemas = vim.tbl_deep_extend('force', new_config.settings.yaml.schemas or {}, require('schemastore').yaml.schemas())
      end,
      settings = {
        redhat = { telemetry = { enabled = false } },
        yaml = {
          keyOrdering = false,
          format = {
            enable = true,
          },
          validate = true,
          schemaStore = {
            -- Must disable built-in schemaStore support to use
            -- schemas from SchemaStore.nvim plugin
            enable = false,
            -- Avoid TypeError: Cannot read properties of undefined (reading 'length')
            url = '',
          },
        },
      },
    },

    -- JSON
    jsonls = {
      root_dir = get_root_dir { '.git' },
      on_new_config = function(new_config)
        new_config.settings.json.schemas = new_config.settings.json.schemas or {}
        vim.list_extend(new_config.settings.json.schemas, require('schemastore').json.schemas())
      end,
      settings = {
        json = {
          format = {
            enable = true,
          },
          validate = { enable = true },
        },
      },
    },

    -- Docker
    dockerls = {
      root_dir = get_root_dir { 'Dockerfile', '.git' },
    },
    docker_compose_language_service = {
      root_dir = get_root_dir { 'docker-compose.yaml', 'docker-compose.yml', 'compose.yaml', 'compose.yml', '.git' },
    },

    -- Terraform
    terraformls = {
      root_dir = get_root_dir { '.terraform', '.git' },
    },
    tflint = {
      root_dir = get_root_dir { '.tflint.hcl', '.terraform', '.git' },
    },

    -- Ansible
    ansiblels = {
      root_dir = get_root_dir { 'ansible.cfg', '.ansible-lint', '.git' },
    },

    -- Nix
    nil_ls = {
      root_dir = get_root_dir { 'flake.nix', 'default.nix', 'shell.nix', '.git' },
      settings = {
        ['nil'] = {
          nix = {
            flake = {
              autoArchive = true,
            },
          },
          formatting = {
            command = { 'nixfmt' },
          },
        },
      },
    },

    -- Markdown
    marksman = {
      root_dir = get_root_dir { '.marksman.toml', '.git' },
    },

    -- TOML
    taplo = {
      root_dir = get_root_dir { '.git' },
      keys = {
        {
          'K',
          function()
            if vim.fn.expand '%:t' == 'Cargo.toml' and require('crates').popup_available() then
              require('crates').show_popup()
            else
              vim.lsp.buf.hover()
            end
          end,
          desc = 'Show Crate Documentation',
        },
      },
    },

    -- Helm
    helm_ls = {
      root_dir = get_root_dir { 'Chart.yaml', '.git' },
    },

    -- Bash
    bashls = {
      root_dir = get_root_dir { '.git' },
    },
  }
end

return M
