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
      nvim-treesitter.withAllGrammars
      nvim-treesitter-textobjects

      # Language-support
      vimtex
      helm-ls-nvim
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
      (pkgs.vimUtils.buildVimPlugin {
        name = "sfer-nvim";
        src = pkgs.fetchFromGitHub {
          owner = "fguisso";
          repo = "sfer.nvim";
          rev = "main";
          hash = "sha256-cEFHm1a4vank2AknpzDhoVzUU55maZVSheHONcDOjEA=";
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

      # Rust
      rust-analyzer
      rustfmt

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

      # DevOps
      terraform-ls
      tflint
      taplo
      yaml-language-server
      docker-language-server
      helm-ls
    ];
  };
}
