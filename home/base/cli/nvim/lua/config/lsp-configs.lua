local function get_root_dir(patterns)
  return function(fname) return vim.fs.root(fname, patterns) end
end

-- Export all language configurations
return {
  -- ============================================================================
  -- ANSIBLE
  -- ============================================================================
  ansible = {
    lsp = {
      ansiblels = {
        root_dir = get_root_dir { 'ansible.cfg', '.ansible-lint', '.git' },
      },
    },
    format = {},
    lint = {},
    plugins = {
      {
        'mfussenegger/nvim-ansible',
        ft = { 'yaml.ansible', 'ansible' },
        config = function()
          -- Automatically detect Ansible files
          vim.api.nvim_create_autocmd({ 'BufRead', 'BufNewFile' }, {
            pattern = {
              '*/playbooks/*.yml',
              '*/playbooks/*.yaml',
              '*/roles/*/tasks/*.yml',
              '*/roles/*/tasks/*.yaml',
              '*/roles/*/handlers/*.yml',
              '*/roles/*/handlers/*.yaml',
              '*/ansible/*.yml',
              '*/ansible/*.yaml',
              '*play*.yml',
              '*play*.yaml',
            },
            callback = function() vim.bo.filetype = 'yaml.ansible' end,
          })
        end,
      },
    },
  },

  -- ============================================================================
  -- BASH/SHELL
  -- ============================================================================
  bash = {
    lsp = {
      bashls = {
        root_dir = get_root_dir { '.git' },
      },
    },
    format = {
      sh = { 'shfmt' },
      bash = { 'shfmt' },
    },
    lint = {},
  },

  -- ============================================================================
  -- C/C++
  -- ============================================================================
  c = {
    lsp = {
      clangd = {
        root_dir = get_root_dir {
          '.clangd',
          '.clang-tidy',
          '.clang-format',
          'compile_commands.json',
          'compile_flags.txt',
          'configure.ac',
          '.git',
        },
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
    },
    format = {},
    lint = {},
  },

  -- ============================================================================
  -- DOCKER
  -- ============================================================================
  docker = {
    lsp = {
      dockerls = {
        root_dir = get_root_dir { 'Dockerfile', '.git' },
      },
      docker_compose_language_service = {
        root_dir = get_root_dir { 'docker-compose.yaml', 'docker-compose.yml', 'compose.yaml', 'compose.yml', '.git' },
      },
    },
    format = {},
    lint = {
      dockerfile = { 'hadolint' },
    },
  },

  -- ============================================================================
  -- GO
  -- ============================================================================
  go = {
    lsp = {
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
    },
    format = {
      go = { 'gofumpt' },
    },
    lint = {
      go = { 'golangcilint' },
    },
  },

  -- ============================================================================
  -- HELM
  -- ============================================================================
  helm = {
    lsp = {
      helm_ls = {
        root_dir = get_root_dir { 'Chart.yaml', '.git' },
      },
    },
    format = {},
    lint = {},
  },

  -- ============================================================================
  -- JSON
  -- ============================================================================
  json = {
    lsp = {
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
    },
    format = {
      json = { 'prettierd', 'prettier', stop_after_first = true },
      jsonc = { 'prettierd', 'prettier', stop_after_first = true },
    },
    lint = {},
  },

  -- ============================================================================
  -- LUA
  -- ============================================================================
  lua = {
    lsp = {
      lua_ls = {
        root_dir = get_root_dir {
          '.luarc.json',
          '.luarc.jsonc',
          '.luacheckrc',
          '.stylua.toml',
          'stylua.toml',
          'selene.toml',
          'selene.yml',
          '.git',
        },
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
    },
    format = {
      lua = { 'stylua' },
    },
    lint = {},
  },

  -- ============================================================================
  -- MARKDOWN
  -- ============================================================================
  markdown = {
    lsp = {
      marksman = {
        root_dir = get_root_dir { '.marksman.toml', '.git' },
      },
    },
    format = {
      markdown = { 'prettierd', 'prettier', stop_after_first = true },
      ['markdown.mdx'] = { 'prettierd', 'prettier', stop_after_first = true },
    },
    lint = {
      markdown = { 'markdownlint-cli2' },
    },
    plugins = {
      {
        'arminveres/md-pdf.nvim',
        branch = 'main',
        lazy = true,
        keys = {
          {
            '<leader>cp',
            function() require('md-pdf').convert_md_to_pdf() end,
            desc = 'Markdown preview',
          },
        },
        opts = {
          toc = false,
          title_page = false,
        },
      },
    },
  },

  -- ============================================================================
  -- NIX
  -- ============================================================================
  nix = {
    lsp = {
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
    },
    format = {
      nix = { 'nixfmt' },
    },
    lint = {
      nix = { 'nix', 'statix' },
    },
  },

  -- ============================================================================
  -- PYTHON
  -- ============================================================================
  python = {
    lsp = {
      basedpyright = {
        root_dir = get_root_dir {
          'pyproject.toml',
          'setup.py',
          'setup.cfg',
          'requirements.txt',
          'Pipfile',
          'pyrightconfig.json',
          '.git',
        },
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
    },
    format = {
      python = function(bufnr)
        if require('conform').get_formatter_info('ruff_format', bufnr).available then
          return { 'ruff_format' }
        else
          return { 'isort', 'black' }
        end
      end,
    },
    lint = {
      python = { 'mypy', 'ruff' },
    },
  },

  -- ============================================================================
  -- TERRAFORM
  -- ============================================================================
  terraform = {
    lsp = {
      terraformls = {
        root_dir = get_root_dir { '.terraform', '.git' },
      },
      tflint = {
        root_dir = get_root_dir { '.tflint.hcl', '.terraform', '.git' },
      },
    },
    format = {
      terraform = { 'terraform_fmt' },
      tf = { 'terraform_fmt' },
      ['terraform-vars'] = { 'terraform_fmt' },
    },
    lint = {
      terraform = { 'terraform_validate' },
      tf = { 'terraform_validate' },
    },
  },

  -- ============================================================================
  -- TOML
  -- ============================================================================
  toml = {
    lsp = {
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
    },
    format = {
      toml = { 'taplo' },
    },
    lint = {},
  },

  -- ============================================================================
  -- WEB (JavaScript, TypeScript, CSS, HTML, etc.)
  -- ============================================================================
  web = {
    lsp = {},
    format = {
      -- JavaScript
      javascript = { 'prettierd', 'prettier', stop_after_first = true },
      javascriptreact = { 'prettierd', 'prettier', stop_after_first = true },
      -- TypeScript
      typescript = { 'prettierd', 'prettier', stop_after_first = true },
      typescriptreact = { 'prettierd', 'prettier', stop_after_first = true },
      -- Vue
      vue = { 'prettierd', 'prettier', stop_after_first = true },
      -- CSS/SCSS/LESS
      css = { 'prettierd', 'prettier', stop_after_first = true },
      scss = { 'prettierd', 'prettier', stop_after_first = true },
      less = { 'prettierd', 'prettier', stop_after_first = true },
      -- HTML
      html = { 'prettierd', 'prettier', stop_after_first = true },
      -- GraphQL
      graphql = { 'prettierd', 'prettier', stop_after_first = true },
      -- Handlebars
      handlebars = { 'prettierd', 'prettier', stop_after_first = true },
    },
    lint = {},
  },

  -- ============================================================================
  -- YAML
  -- ============================================================================
  yaml = {
    lsp = {
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
    },
    format = {
      yaml = { 'prettierd', 'prettier', stop_after_first = true },
    },
    lint = {
      yaml = { 'ansible_lint', 'yamllint' },
    },
  },
}
