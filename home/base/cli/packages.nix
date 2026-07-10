{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # System
    coreutils-prefixed
    inetutils
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

    # Dev tools
    uv
    nodejs
    devenv
    marp-cli

    # Infrastructure & DevOps
    kubernetes-helm
    kubectl
    krew
    kubelogin-oidc
    kubie
    k9s
    lazydocker
  ];
}
