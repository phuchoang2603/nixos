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
      (nvim-treesitter.withPlugins (p: [
        p.comment
        p.regex
        p.vim
        p.ini
        p.sql
        p.bash
        p.c
        p.cpp
        p.python
        p.go
        p.lua
        p.html
        p.css
        p.javascript
        p.json
        p.nix
        p.latex
        p.markdown
        p.markdown_inline
        p.dockerfile
        p.yaml
        p.toml
        p.starlark
        p.hcl
        p.helm
      ]))
      nvim-treesitter-textobjects
      nvim-lspconfig

      # Language-support
      helm-ls-nvim
      (pkgs.vimUtils.buildVimPlugin {
        name = "sqls-nvim";
        src = pkgs.fetchFromGitHub {
          owner = "nanotee";
          repo = "sqls.nvim";
          rev = "main";
          hash = "sha256-543z6Rjs1ClKYcSrOosX0evxYOdPtYjG05VEvZVoznc=";
        };
        doCheck = false;
      })
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

      # Test
      neotest
      neotest-golang
      neotest-python

      # Debug
      nvim-dap
      nvim-dap-view
      nvim-dap-go
      nvim-dap-python

      # Other
      plenary-nvim
      nvim-nio
      yazi-nvim
      quicker-nvim
      sidekick-nvim
      mini-icons
      gitsigns-nvim
      which-key-nvim
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

      # LSP
      bash-language-server
      copilot-language-server
      vscode-langservers-extracted
      lua-language-server
      nixd
      markdown-oxide
      harper
      yaml-language-server

      # Formatter
      shfmt
      prettierd
      stylua
      nixfmt
    ];
  };
}
