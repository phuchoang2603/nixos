{ pkgs, lib, config, ... }:

{
  # Hyprland (no UWSM)
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  # Login manager (TTY) for Hyprland
  services.greetd = {
    enable = true;
    settings.default_session = {
      user = "greeter";
      command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd Hyprland";
    };
  };

  # XDG portal for screen sharing, file picker, etc.
  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-hyprland
      pkgs.xdg-desktop-portal-gtk
    ];
    config.common.default = "*";
  };

  # Desktop environment packages
  environment.systemPackages = with pkgs; [
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

    # File manager
    nautilus
    file-roller

    # Screenshot/Recording
    grim
    slurp
    swappy
    wf-recorder

    # Display management
    nwg-displays
    kanshi           # Auto display configuration

    # Theming
    pywal

    # GTK theming
    gtk3
    gtk4
    adwaita-icon-theme
    papirus-icon-theme

    # Qt theming
    qt5.qtwayland
    qt6.qtwayland
    libsForQt5.qt5ct
    qt6Packages.qt6ct

    # Cursor theme
    bibata-cursors

    # Authentication agent
    polkit_gnome

    # Network applet
    networkmanagerapplet

    # Bluetooth applet
    blueman

    # Media controls
    playerctl
  ];

  # Enable dconf for GTK settings
  programs.dconf.enable = true;

  # Security/Authentication
  security.polkit.enable = true;

  # Polkit agent (needed for GUI auth prompts on Hyprland)
  systemd.user.services.polkit-gnome-authentication-agent-1 = {
    description = "Polkit GNOME Authentication Agent";
    wantedBy = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
      Restart = "on-failure";
    };
  };

  # Session variables for Wayland
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    XDG_SESSION_TYPE = "wayland";
    XDG_CURRENT_DESKTOP = "Hyprland";
    XDG_SESSION_DESKTOP = "Hyprland";
    XDG_PICTURES_DIR = "$HOME/Pictures/Screenshots/";
    QT_QPA_PLATFORM = "wayland;xcb";
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
    QT_AUTO_SCREEN_SCALE_FACTOR = "1";
    GDK_BACKEND = "wayland,*";
    SDL_VIDEODRIVER = "wayland";
    CLUTTER_BACKEND = "wayland";
    MOZ_ENABLE_WAYLAND = "1";
    XCURSOR_SIZE = "24";
    HYPRCURSOR_SIZE = "24";
    PATH = "./bin:$HOME/.local/bin:$HOME/.config/nix/scripts:$PATH";
  };

  # Enable GNOME keyring for secrets
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.login.enableGnomeKeyring = true;
  security.pam.services.greetd.enableGnomeKeyring = true;

  # Enable GVFS for trash and other virtual filesystems
  services.gvfs.enable = true;

  # Thumbnail service
  services.tumbler.enable = true;
}
