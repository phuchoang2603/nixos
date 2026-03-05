{ pkgs, lib, ... }:

{
  home.packages = with pkgs; [
    microsoft-edge
    vscode
    jetbrains.datagrip
    obsidian
    inotify-tools
    vlc
    todoist
    libreoffice-fresh
    playerctl
    gimp
    zathura
    lutris

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
