{ pkgs, lib, ... }:

{
  home.packages = with pkgs; [
    # System
    coreutils-prefixed
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
    kubernetes-helm
    kubectl
    krew
    kubelogin-oidc
    kubie
    k9s
    tilt
    lazydocker
  ];
}
