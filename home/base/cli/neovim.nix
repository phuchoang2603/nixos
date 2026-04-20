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
      helm-ls-nvim

      # Test
      (pkgs.vimUtils.buildVimPlugin {
        name = "neotest";
        src = pkgs.fetchFromGitHub {
          owner = "nvim-neotest";
          repo = "neotest";
          rev = "master";
          hash = "sha256-tcbO1138SICtWg2ER973KcZvY18QvAW72MW0si6abFI=";
        };
        doCheck = false;
      })
      neotest-golang
      neotest-python

      # Debug
      nvim-dap
      nvim-dap-virtual-text
      nvim-dap-view
      nvim-dap-go
      nvim-dap-python

      # Other
      plenary-nvim
      nvim-nio
      yazi-nvim
      quicker-nvim
      sidekick-nvim

      # Document
      vimtex
      (pkgs.vimUtils.buildVimPlugin {
        name = "live-preview-nvim";
        src = pkgs.fetchFromGitHub {
          owner = "brianhuster";
          repo = "live-preview.nvim";
          rev = "main";
          hash = "sha256-8R4WNFKMz72MoycBK736A5YC8NH1K8TBea2Px4udGZ8=";
        };
        doCheck = false;
      })

      # UI stuff
      mini-icons
      mini-statusline
      gitsigns-nvim
      which-key-nvim
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
      sqruff

      # BASH / SHELL
      bash-language-server
      shfmt

      # C / C++
      clang-tools

      # GO / GRPC
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
