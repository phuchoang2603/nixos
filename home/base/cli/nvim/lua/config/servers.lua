-- Central place to configure all LSP servers
local M = {}

function M.get_servers()
  return {
    -- Lua
    lua_ls = {
      on_init = function(client)
        if client.workspace_folders then
          local path = client.workspace_folders[1].name
          if path ~= vim.fn.stdpath 'config' and (vim.uv.fs_stat(path .. '/.luarc.json') or vim.uv.fs_stat(path .. '/.luarc.jsonc')) then return end
        end

        client.config.settings.Lua = vim.tbl_deep_extend('force', client.config.settings.Lua, {
          runtime = {
            version = 'LuaJIT',
            path = { 'lua/?.lua', 'lua/?/init.lua' },
          },
          workspace = {
            checkThirdParty = false,
            library = vim.api.nvim_get_runtime_file('', true),
          },
        })
      end,
      settings = {
        Lua = {},
      },
    },

    -- C/C++
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
    },

    -- Go
    gopls = {
      settings = {
        gopls = {
          gofumpt = true,
          analyses = {
            unusedparams = true,
          },
          staticcheck = true,
        },
      },
    },

    -- Python
    pyright = {
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
    dockerls = {},
    docker_compose_language_service = {},

    -- Terraform
    terraformls = {},
    tflint = {},

    -- Ansible
    ansiblels = {},

    -- Nix
    nil_ls = {
      settings = {
        ['nil'] = {
          formatting = {
            command = { 'nixfmt' },
          },
        },
      },
    },

    -- Markdown
    marksman = {},

    -- TOML
    taplo = {},

    -- Helm
    helm_ls = {},

    -- Git (commit messages, etc)
    -- Note: This doesn't exist as a standalone LSP, handled by other plugins
  }
end

return M
