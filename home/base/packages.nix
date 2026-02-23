{ pkgs, lib, ... }:

{
  home.packages =
    with pkgs;
    [
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

      # GUI applications
      microsoft-edge
      vscode
      jetbrains.datagrip
      obsidian
      mupdf
    ]
    ++ lib.optionals pkgs.stdenv.hostPlatform.isDarwin [
      # --- macOS Only ---
      hidden-bar
      raycast
    ]
    ++ lib.optionals (!pkgs.stdenv.hostPlatform.isDarwin) [
      # --- Linux Only ---
      vlc
      todoist
      libreoffice-fresh
      playerctl
      gimp

      # Wayland Essentials
      wayland
      wayland-utils
      wayland-protocols
      wl-clipboard
      wlr-randr
      libnotify

      # Qt Theming
      qt5.qtwayland
      qt6.qtwayland
      libsForQt5.qt5ct
      qt6Packages.qt6ct

      # Linux Utilities
      mission-center
      gnome-calculator
      gnome-clocks
      baobab
      sushi
      localsend
      blueman
      pciutils
      usbutils
      nautilus
    ];
}
