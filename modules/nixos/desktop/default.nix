{ pkgs, lib, config, ... }:

{
  imports = [
    ./input-methods.nix
  ];

  # Hyprland (system-level)
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  # Login manager (TTY) for Hyprland
  services.greetd = {
    enable = true;
    settings.default_session = {
      user = "greeter";
      command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd start-hyprland";
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
    GTK_THEME = "Adwaita-dark";
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
