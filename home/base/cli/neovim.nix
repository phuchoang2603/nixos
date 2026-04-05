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
    initLua = ''
      require("config")
      require("plugins")
    '';

    plugins = with pkgs.vimPlugins; [
      # LSP related
      blink-cmp
      friendly-snippets
      conform-nvim
      nvim-treesitter
      (nvim-treesitter.withPlugins (p: [
        p.comment
        p.markdown
        p.markdown_inline
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
      neotest
      neotest-golang
      neotest-python
      helm-ls-nvim

      # Other
      plenary-nvim
      nvim-nio
      yazi-nvim
      quicker-nvim
      sidekick-nvim

      # Document
      vimtex
      live-preview-nvim

      # UI stuff
      mini-icons
      mini-statusline
      gitsigns-nvim
      which-key-nvim
      noice-nvim
      nui-nvim
      snacks-nvim
      todo-comments-nvim

      # My Neovim config
      (pkgs.vimUtils.buildVimPlugin {
        name = "my-neovim-config";
        src = ./nvim;
        doCheck = false;
      })
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
}
