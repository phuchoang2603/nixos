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
          semanticTokens = true,
        },
      },
    },

    -- Python
    pyright = {
      root_dir = get_root_dir { 'pyproject.toml', 'setup.py', 'setup.cfg', 'requirements.txt', 'Pipfile', 'pyrightconfig.json', '.git' },
      settings = {
        python = {
          analysis = {
            typeCheckingMode = 'basic',
            autoSearchPaths = true,
            useLibraryCodeForTypes = true,
          },
        },
      },
    },

    -- YAML
    yamlls = {
      root_dir = get_root_dir { '.git' },
      settings = {
        yaml = {
          schemas = {
            kubernetes = '*.yaml',
            ['http://json.schemastore.org/github-workflow'] = '.github/workflows/*',
            ['http://json.schemastore.org/github-action'] = '.github/action.{yml,yaml}',
            ['http://json.schemastore.org/ansible-stable-2.9'] = 'roles/tasks/*.{yml,yaml}',
            ['http://json.schemastore.org/prettierrc'] = '.prettierrc.{yml,yaml}',
            ['http://json.schemastore.org/kustomization'] = 'kustomization.{yml,yaml}',
            ['http://json.schemastore.org/ansible-playbook'] = '*play*.{yml,yaml}',
            ['http://json.schemastore.org/chart'] = 'Chart.{yml,yaml}',
            ['https://json.schemastore.org/dependabot-v2'] = '.github/dependabot.{yml,yaml}',
            ['https://json.schemastore.org/gitlab-ci'] = '*gitlab-ci*.{yml,yaml}',
            ['https://raw.githubusercontent.com/OAI/OpenAPI-Specification/main/schemas/v3.1/schema.json'] = '*api*.{yml,yaml}',
          },
          format = {
            enable = true,
          },
          validate = true,
        },
      },
    },

    -- JSON
    jsonls = {
      root_dir = get_root_dir { '.git' },
      settings = {
        json = {
          schemas = (function()
            local ok, schemastore = pcall(require, 'schemastore')
            if ok then return schemastore.json.schemas() end
            return {}
          end)(),
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
