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
    ffmpeg
    ffmpegthumbnailer
    poppler
    imagemagick
    fastfetch
    btop
    htop

    # Lang
    python3
    go
    rustc
    cargo

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
