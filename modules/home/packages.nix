{ pkgs, lib, ... }:

{
  home.packages = with pkgs; [
    # Editors & Dev
    neovim
    tree-sitter
    luarocks
    opencode

    # Languages & IaC
    nodejs
    go
    python3
    uv
    rustc
    cargo
    terraform
    gcc

    # Git tools
    lazygit
    gh

    # Monitoring
    fastfetch
    btop

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

    # Kubernetes
    kubectl
    kubernetes-helm
    kubectx
    krew

    # Docker
    lazydocker
  ];
}
