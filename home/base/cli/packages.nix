{ pkgs, lib, ... }:

{
  home.packages = with pkgs; [
    # System
    vim
    wget
    curl
    _7zz
    unzip
    gcc
    jq
    fd
    nh
    rclone
    ripgrep
    ffmpegthumbnailer
    poppler
    imagemagick
    fastfetch
    btop
    htop

    # Infrastructure & DevOps
    terraform
    ansible
    kubernetes-helm
    kubectl
    kubectx
    krew
    lazydocker
  ];
}
