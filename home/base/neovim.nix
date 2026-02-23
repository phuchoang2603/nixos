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
      # LSP related
      blink-cmp # completion
      luasnip # snippets
      friendly-snippets # snippets
      quicker-nvim # quickfix
      conform-nvim # format
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

      # Core
      plenary-nvim
      opencode-nvim

      # Mini ecosystem
      mini-surround
      mini-pairs
      mini-icons
      mini-statusline

      # Document
      vimtex
      live-preview-nvim

      # UI stuff
      base16-nvim
      gitsigns-nvim
      yazi-nvim
      which-key-nvim
      noice-nvim
      nui-nvim
      snacks-nvim
      todo-comments-nvim
    ];

    extraPackages = with pkgs; [
      tree-sitter
      lsof
      inotify-tools
      copilot-language-server

      # BASH / SHELL
      bash-language-server
      shfmt

      # C / C++
      clang-tools

      # DOCKER
      docker-language-server

      # GO
      gopls
      gotools
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

      # PYTHON
      basedpyright
      ruff
      black
      isort

      # TERRAFORM
      terraform-ls
      tflint

      # TOML
      taplo

      # WEB (JavaScript/TypeScript/CSS/HTML)
      prettierd

      # YAML
      yaml-language-server
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
