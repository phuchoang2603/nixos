{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # Nix
    nixd # LSP
    statix # Linter
    nixfmt # Formatter

    # Documentation & Markup
    marksman # Markdown LSP
    markdownlint-cli2 # Markdown Linter (Recommended)

    # Lua
    luarocks # Package Manager
    lua-language-server # LSP
    stylua # Formatter

    # Web & Configs (Node/JSON/YAML/TOML)
    nodejs # Runtime
    prettier # Multi-tool Formatter
    vscode-langservers-extracted # LSPs for JSON, HTML, CSS
    yaml-language-server # LSP
    yamlfmt # Formatter
    taplo # TOML LSP & Formatter

    # General Tooling & Editor Support
    tree-sitter # Syntax Highlighting Parser
    llvmPackages.lldb # General Debugger
    bash-language-server # Bash LSP
    shfmt # Shell Formatter
    shellcheck # Shell Linter

    # Infrastructure & DevOps
    kubernetes-helm # Helm CLI
    helm-ls # Helm LSP
    kubectl # K8s CLI
    kubectx # K8s Tool
    krew # K8s Plugin Manager
    lazydocker # Docker TUI

    # System
    vim
    git
    lazygit
    wget
    curl
    unzip
    lsof
    gcc

    # Monitoring
    fastfetch
    btop
    htop

    # File manager dependencies
    ffmpegthumbnailer
    poppler
    imagemagick

    # Utils
    rclone
    jq
    fd
    ripgrep
    todoist

    # Tmux ecosystem
    gitmux
    sesh
  ];

  programs = {
    # Atuin - shell history
    atuin = {
      enable = true;
      enableZshIntegration = true;
    };

    # FZF - fuzzy finder
    fzf = {
      enable = true;
      enableZshIntegration = true;

      defaultCommand = "fd --type f --hidden --strip-cwd-prefix --exclude .git";
      defaultOptions = [
        "--height 40%"
        "--layout=reverse"
        "--border"
      ];

      fileWidgetCommand = "fd --type f --hidden --strip-cwd-prefix --exclude .git";
      fileWidgetOptions = [
        "--preview 'bat --color=always --style=numbers --line-range=:500 {}'"
      ];

      changeDirWidgetCommand = "fd --type directory --hidden";
      changeDirWidgetOptions = [
        "--preview 'eza -1 --color=always {} || ls --color=always {}'"
      ];
    };

    # Zoxide - smart cd
    zoxide = {
      enable = true;
      enableZshIntegration = true;
    };

    # Bat - cat replacement
    bat = {
      enable = true;
    };

    # Eza - ls replacement
    eza = {
      enable = true;
      icons = "auto";
      git = true;
    };
  };
}
