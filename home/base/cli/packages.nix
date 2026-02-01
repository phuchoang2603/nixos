{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # Nix
    nixd # LSP
    statix # Linter
    nixfmt # Formatter
    alejandra # Alternative Formatter (common for Nix)

    # Python
    python3 # Runtime
    uv # Package/Env Manager
    pyright # LSP
    ruff # Linter & Formatter

    # Go
    go # Runtime
    gopls # LSP
    go-tools # Staticcheck, etc.
    delve # Debugger (DAP)
    golangci-lint # Linter (Recommended for Go extra)

    # C / C++
    gcc # Compiler
    clang-tools # LSP (clangd) & Formatter
    cmake-language-server # LSP
    gdb # Debugger

    # Lua
    lua
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

    # Infrastructure & DevOps
    terraform # CLI
    terraform-ls # LSP
    dockerfile-language-server # LSP
    hadolint # Docker Linter (Highly recommended)
    kubernetes-helm # Helm CLI
    helm-ls # Helm LSP
    kubectl # K8s CLI
    kubectx # K8s Tool
    krew # K8s Plugin Manager
    lazydocker # Docker TUI
    ansible-lint # Linter

    # Documentation & Markup
    marksman # Markdown LSP
    markdownlint-cli # Markdown Linter (Recommended)
    texlab # LaTeX LSP

    # General Tooling & Editor Support
    tree-sitter # Syntax Highlighting Parser
    shfmt # Shell Formatter
    shellcheck # Shell Linter (Recommended)
    llvmPackages.lldb # General Debugger (C/Rust)

    # System
    vim
    git
    lazygit
    wget
    curl
    unzip

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
