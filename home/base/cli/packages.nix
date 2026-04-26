{ pkgs, ... }:

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

    # Infrastructure & DevOps
    kubernetes-helm
    kubectl
    krew
    kubelogin-oidc
    kubie
    k9s
    lazydocker
    devenv
  ];
}
