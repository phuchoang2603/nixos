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
      friendly-snippets # snippets
      conform-nvim # format
      (nvim-treesitter.withPlugins (p: [
        p.comment
        p.markdown
        p.markdown_inline
        p.query
        p.vim
        p.json
        p.xml
        p.yaml
        p.ini
        p.toml
        p.bash
        p.c
        p.cpp
        p.python
        p.go
        p.lua
        p.html
        p.css
        p.javascript
        p.typescript
        p.sql
        p.nix
        p.latex
        p.dockerfile
        p.starlark
        p.hcl
        p.helm
      ]))
      nvim-treesitter-textobjects
      helm-ls-nvim

      # Core
      plenary-nvim
      quicker-nvim

      # Document
      vimtex
      live-preview-nvim

      # UI stuff
      mini-icons
      mini-statusline
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
      copilot-language-server

      # BASH / SHELL
      bash-language-server
      shfmt

      # C / C++
      clang-tools

      # GO
      gopls
      gotools
      gofumpt
      protols

      # JSON / HTML / CSS / JavaScript
      vscode-langservers-extracted
      typescript-go
      prettierd

      # LUA
      lua-language-server
      stylua

      # Documents
      markdown-oxide
      texlab
      harper

      # NIX
      nixd
      nixfmt

      # PYTHON
      ty
      ruff
      black
      isort

      # DevOps
      terraform-ls
      tflint
      tilt
      docker-language-server
      helm-ls
      taplo
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
