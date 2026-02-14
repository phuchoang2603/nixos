-- Consolidated LSP, formatter, and linter configurations for all languages
-- Uses Neovim 0.11+ native LSP API (vim.lsp.config + vim.lsp.enable)

return {
  -- ============================================================================
  -- ANSIBLE
  -- ============================================================================
  ansible = {
    lsp = {
      ansiblels = {
        cmd = { 'ansible-language-server', '--stdio' },
        filetypes = { 'yaml.ansible' },
        root_markers = { 'ansible.cfg', '.ansible-lint' },
      },
    },
    format = {},
    lint = {},
    plugins = {
      {
        'mfussenegger/nvim-ansible',
        ft = { 'yaml.ansible' },
      },
    },
  },

  -- ============================================================================
  -- BASH/SHELL
  -- ============================================================================
  bash = {
    lsp = {
      bashls = {
        cmd = { 'bash-language-server', 'start' },
        filetypes = { 'sh', 'bash' },
        root_markers = { '.git' },
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
        cmd = {
          'clangd',
          '--background-index',
          '--clang-tidy',
          '--header-insertion=iwyu',
          '--completion-style=detailed',
          '--function-arg-placeholders',
          '--fallback-style=llvm',
        },
        filetypes = { 'c', 'cpp', 'objc', 'objcpp', 'cuda' },
        root_markers = {
          '.clangd',
          '.clang-tidy',
          '.clang-format',
          'compile_commands.json',
          'compile_flags.txt',
          'configure.ac',
          '.git',
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
        cmd = { 'docker-langserver', '--stdio' },
        filetypes = { 'dockerfile' },
        root_markers = { 'Dockerfile', '.git' },
      },
      docker_compose_language_service = {
        cmd = { 'docker-compose-langserver', '--stdio' },
        filetypes = { 'yaml.docker-compose' },
        root_markers = { 'docker-compose.yaml', 'docker-compose.yml', 'compose.yaml', 'compose.yml', '.git' },
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
        cmd = { 'gopls' },
        filetypes = { 'go', 'gomod', 'gowork', 'gotmpl' },
        root_markers = { 'go.work', 'go.mod', '.git' },
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
        cmd = { 'helm_ls', 'serve' },
        filetypes = { 'helm' },
        root_markers = { 'Chart.yaml', '.git' },
      },
    },
    format = {},
    lint = {},
    plugins = {
      { 'qvalentin/helm-ls.nvim', ft = 'helm' },
    },
  },

  -- ============================================================================
  -- JSON
  -- ============================================================================
  json = {
    lsp = {
      jsonls = {
        cmd = { 'vscode-json-language-server', '--stdio' },
        filetypes = { 'json', 'jsonc' },
        root_markers = { '.git' },
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
        cmd = { 'lua-language-server' },
        filetypes = { 'lua' },
        root_markers = {
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
        cmd = { 'marksman', 'server' },
        filetypes = { 'markdown', 'markdown.mdx' },
        root_markers = { '.marksman.toml', '.git' },
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
      nixd = {
        cmd = { 'nixd' },
        filetypes = { 'nix' },
        root_markers = { 'flake.nix', 'default.nix', 'shell.nix', '.git' },
        settings = {
          nixd = {
            formatting = {
              command = { 'nixfmt' },
            },
            nixpkgs = {
              expr = 'import (builtins.getFlake(toString ./.)).inputs.nixpkgs { }',
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
        cmd = { 'basedpyright-langserver', '--stdio' },
        filetypes = { 'python' },
        root_markers = {
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
        cmd = { 'ruff', 'server', '--preview' },
        filetypes = { 'python' },
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
        cmd = { 'terraform-ls', 'serve' },
        filetypes = { 'terraform', 'terraform-vars' },
        root_markers = { '.terraform', '.git' },
      },
      tflint = {
        cmd = { 'tflint', '--langserver' },
        filetypes = { 'terraform' },
        root_markers = { '.tflint.hcl', '.terraform', '.git' },
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
        cmd = { 'taplo', 'lsp', 'stdio' },
        filetypes = { 'toml' },
        root_markers = { '.git' },
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
        cmd = { 'yaml-language-server', '--stdio' },
        filetypes = { 'yaml' },
        root_markers = { '.git' },
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
              enable = false,
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
