{
  config,
  lib,
  pkgs,
  ...
}:

{
  programs.neovim = {
    enable = true;
    vimAlias = true;
    viAlias = true;
  };

  home.packages = with pkgs; [
    # LSP Servers
    lua-language-server # Lua
    nil # Nix
    marksman # Markdown
    taplo # TOML
    yaml-language-server # YAML
    nodePackages.vscode-langservers-extracted # JSON, HTML, CSS, ESLint
    nodePackages.bash-language-server # Bash
    helm-ls # Helm

    # Formatters
    stylua # Lua
    nixfmt-classic # Nix (or nixfmt-rfc-style)
    nodePackages.prettier # Web formats (JS/TS/JSON/YAML/Markdown)
    prettierd # Prettier daemon (faster)
    shfmt # Shell

    # Linters
    statix # Nix
    yamllint # YAML
    nodePackages.markdownlint-cli2 # Markdown
    hadolint # Dockerfile
  ];

  xdg.configFile = {
    "nvim/lua" = {
      source = ./nvim/lua;
      recursive = true;
    };
    "nvim/init.lua".source = ./nvim/init.lua;
    "nvim/.stylua.toml".source = ./nvim/.stylua.toml;
  };
}
