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

    plugins = with pkgs.vimPlugins; [
      # Core
      plenary-nvim

      # LSP related
      blink-cmp
      luasnip
      trouble-nvim
      conform-nvim
      (nvim-treesitter.withPlugins (p: [
        # Core / Utils
        p.gitignore
        p.gitcommit
        p.git_rebase
        p.git_config
        p.diff
        p.comment
        p.markdown
        p.markdown_inline
        p.query
        p.regex
        p.vim
        p.vimdoc
        p.json
        p.xml
        p.yaml
        p.ini
        p.toml
        # Programming Languages
        p.bash
        p.c
        p.cpp
        p.python
        p.go
        p.gomod
        p.gowork
        p.gosum
        p.lua
        p.luadoc
        p.html
        p.css
        p.javascript
        p.typescript
        p.tsx
        p.sql
        p.nix
        p.latex
        p.bibtex
        # DevOps & Infrastructure
        p.dockerfile
        p.terraform
        p.hcl
        p.helm
      ]))
      nvim-treesitter-textobjects

      # Mini ecosystem
      mini-surround
      mini-pairs
      mini-icons
      mini-statusline

      # Document
      vimtex
      live-preview-nvim

      # UI stuff
      gitsigns-nvim
      yazi-nvim
      which-key-nvim
      noice-nvim
      nui-nvim
      snacks-nvim
      base16-nvim
    ];

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
