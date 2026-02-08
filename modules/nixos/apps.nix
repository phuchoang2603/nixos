{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # Media
    playerctl
    vlc
    mpv
    gimp
    zathura

    # GUI Applications
    microsoft-edge
    vscode
    jetbrains.datagrip
    libreoffice-fresh
    obsidian
    nautilus
    copyq

    # Wayland essentials
    wayland
    wayland-utils
    wayland-protocols
    wl-clipboard
    wlr-randr
    libnotify

    # Qt theming
    qt5.qtwayland
    qt6.qtwayland
    libsForQt5.qt5ct
    qt6Packages.qt6ct

    # Screenshot/Recording
    hyprpicker
    hyprshot
    grim
    slurp
    swappy
    wf-recorder

    # Utilities
    mission-center # Task manager
    gnome-calculator
    gnome-clocks
    baobab # Disk usage analyzer
    sushi
    localsend
    blueman
    pciutils
    usbutils
    nh
  ];
}
