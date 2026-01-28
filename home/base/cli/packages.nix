{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # System
    vim
    git
    wget
    curl
    unzip
    pciutils
    usbutils

    # Languages & Lint $ Formatter
    nodejs
    go
    uv
    rustc
    cargo
    gcc
    tree-sitter
    luarocks
    statix
    nixfmt

    # --- LSPs (Language Servers) ---
    nixd
    lua-language-server
    marksman
    pyright
    gopls
    terraform-ls
    yaml-language-server
    clang-tools
    cmake-language-server
    dockerfile-language-server
    helm-ls
    texlab
    taplo
    vscode-langservers-extracted

    # --- Formatters ---
    nixfmt
    stylua
    ruff
    yamlfmt
    ansible-lint
    shfmt

    # --- Debuggers ---
    llvmPackages.lldb
    delve

    # DevOps
    kubectl
    kubernetes-helm
    kubectx
    krew
    terraform
    lazydocker
    lazygit

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
