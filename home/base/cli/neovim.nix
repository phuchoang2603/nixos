{
  config,
  lib,
  pkgs,
  ...
}:

{
  programs.neovim = {
    enable = true;
    vimAlias = true;
    viAlias = true;
  };

  home.packages = with pkgs; [
    # LSP Servers
    lua-language-server # Lua
    nil # Nix
    marksman # Markdown
    taplo # TOML
    yaml-language-server # YAML
    vscode-langservers-extracted # JSON, HTML, CSS, ESLint
    bash-language-server # Bash
    helm-ls # Helm

    # Language-specific LSP servers
    basedpyright # Python type checker
    ruff # Python linter/formatter LSP
    gopls # Go
    clang-tools # clangd for C/C++
    terraform-ls # Terraform
    tflint # Terraform linter
    dockerfile-language-server # Docker
    docker-compose-language-service # Docker Compose

    # Formatters
    stylua # Lua
    nixfmt # Nix
    prettierd # Prettier daemon (faster)
    shfmt # Shell
    black # Python
    isort # Python imports
    gotools # gofumpt and other Go tools

    # Linters
    statix # Nix
    yamllint # YAML
    markdownlint-cli2 # Markdown
    hadolint # Dockerfile
    mypy # Python type checker
    golangci-lint # Go
    ansible-lint # Ansible
  ];

  xdg.configFile = {
    "nvim/lua" = {
      source = ./nvim/lua;
      recursive = true;
    };
    "nvim/init.lua".source = ./nvim/init.lua;
    "nvim/.stylua.toml".source = ./nvim/.stylua.toml;
  };
}
