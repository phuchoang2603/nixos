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
}
