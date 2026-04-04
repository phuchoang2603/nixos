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
    extraLuaConfig = ''
      require("config")
      require("plugins")
    '';

    plugins = with pkgs.vimPlugins; [
      # LSP related
      blink-cmp
      friendly-snippets
      conform-nvim
      nvim-treesitter.withAllGrammars
      nvim-treesitter-textobjects
      helm-ls-nvim

      # Other
      plenary-nvim
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
