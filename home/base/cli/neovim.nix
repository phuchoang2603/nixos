{
  pkgs,
  ...
}:

{
  programs.neovim = {
    enable = true;
    vimAlias = true;
    viAlias = true;
    defaultEditor = true;

    plugins = with pkgs.vimPlugins; [
      lazy-nvim
    ];

    extraPackages = with pkgs; [
      # ANSIBLE
      ansible-language-server
      ansible-lint

      # BASH / SHELL
      bash-language-server
      shfmt

      # C / C++
      clang-tools

      # DOCKER
      dockerfile-language-server
      docker-compose-language-service
      hadolint # Dockerfile linter

      # GO
      gopls
      gotools
      golangci-lint
      gofumpt

      # HELM
      helm-ls

      # JSON / HTML / CSS / ESLINT
      vscode-langservers-extracted

      # LUA
      lua-language-server
      stylua

      # MARKDOWN
      marksman
      markdownlint-cli2

      # NIX
      nixd
      nixfmt
      statix # Nix linter

      # PYTHON
      basedpyright
      ruff # Python linter/formatter LSP
      black
      isort
      mypy

      # TERRAFORM
      terraform-ls
      tflint

      # TOML
      taplo

      # WEB (JavaScript/TypeScript/CSS/HTML)
      prettierd # Prettier daemon for faster formatting

      # YAML
      yaml-language-server
      yamllint
    ];
  };

  xdg.configFile = {
    "nvim/lua" = {
      source = ./nvim/lua;
      recursive = true;
    };

    "nvim/init.lua".source = ./nvim/init.lua;
    "nvim/.stylua.toml".source = ./nvim/.stylua.toml;
  };
}
