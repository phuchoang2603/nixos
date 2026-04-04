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

    # Lang
    python3
    go

    # Infrastructure & DevOps
    terraform
    ansible
    tilt
    kubernetes-helm
    kubectl
    kubectx
    minikube
    krew
    lazydocker
    awscli2
    google-cloud-sdk
  ];
}
