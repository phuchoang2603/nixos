{
  pkgs,
  inputs,
  ...
}:

{
  programs.neovim = {
    enable = true;
    package = inputs.neovim-nightly-overlay.packages.${pkgs.system}.default;
    vimAlias = true;
    viAlias = true;
    defaultEditor = true;

    extraPackages = with pkgs; [
      tree-sitter
      lsof
      inotify-tools

      # ANSIBLE
      ansible-language-server
      ansible-lint

      # BASH / SHELL
      bash-language-server
      shfmt

      # C / C++
      clang-tools

      # DOCKER
      docker-language-server
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

    "nvim/lsp" = {
      source = ./nvim/lsp;
      recursive = true;
    };

    "nvim/init.lua".source = ./nvim/init.lua;
  };
}
