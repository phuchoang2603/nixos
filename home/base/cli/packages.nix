{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # System
    vim
    git
    wget
    curl
    _7zz
    unzip
    gcc

    # Infrastructure & DevOps
    terraform
    ansible
    kubernetes-helm
    kubectl
    kubectx
    krew
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
