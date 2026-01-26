{ pkgs, lib, config, ... }:

{
  environment.systemPackages = with pkgs; [
    # Browsers
    microsoft-edge



    # Development
    vscode

    # Note-taking
    obsidian

    # Office
    libreoffice-fresh

    # Media
    vlc
    mpv

    # Image editing
    gimp

    # PDF viewer
    zathura

    # System monitoring
    mission-center   # Task manager

    # Utilities
    gnome-calculator
    gnome-clocks
    baobab           # Disk usage analyzer

    # Clipboard manager
    copyq

    # Quick preview for GNOME Files
    sushi

    # Text expander
    espanso-wayland

    # Local file sharing
    localsend

    # Wayland essentials
    wayland
    wayland-utils
    wayland-protocols
    wl-clipboard
    wlr-randr
    wlsunset

    # Hyprland ecosystem
    hyprpaper        # Wallpaper
    hyprlock         # Lock screen
    hypridle         # Idle daemon
    hyprpicker       # Color picker

    # Status bar
    waybar

    # Notifications
    mako
    libnotify

    # Application launcher
    rofi
    rofi-calc

    # File manager
    nautilus

    # Screenshot/Recording
    grim
    slurp
    swappy
    wf-recorder

    # Display management
    nwg-displays

    # GTK theming (handled by Stylix)
    adwaita-icon-theme
    papirus-icon-theme

    # Qt theming
    qt5.qtwayland
    qt6.qtwayland
    libsForQt5.qt5ct
    qt6Packages.qt6ct

    # Authentication agent
    polkit_gnome

    # Bluetooth applet
    blueman

    # Media controls
    playerctl
  ];

}
