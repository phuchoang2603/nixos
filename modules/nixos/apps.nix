{ pkgs, lib, config, ... }:

{
  # GUI Applications
  environment.systemPackages = with pkgs; [
    # Browsers
    microsoft-edge

    # Theming
    pywal

    # Development
    vscode
    # Note: neovim is in home-manager packages

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
  ];

  # Steam (if gaming is needed)
  # programs.steam = {
  #   enable = true;
  #   remotePlay.openFirewall = true;
  #   dedicatedServer.openFirewall = true;
  # };
}
