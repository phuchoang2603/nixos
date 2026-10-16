{
  pkgs,
  ...
}:

{
  programs.neovim = {
    enable = true;
    # Use the stable Neovim release from nixpkgs.
    package = pkgs.neovim-unwrapped;

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
      nvim-treesitter.withAllGrammars
      nvim-treesitter-textobjects
      nvim-lspconfig

      # Language-support
      helm-ls-nvim
      live-preview-nvim

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
      ty
      gopls
      bash-language-server
      vscode-langservers-extracted
      lua-language-server
      nixd
      markdown-oxide
      harper
      yaml-language-server

      # Formatter
      shfmt
      stylua
      nixfmt
      oxfmt
    ];
  };
}
