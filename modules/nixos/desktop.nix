{ pkgs, ... }:

{
  # Hyprland (system-level)
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  services = {
    # Login manager (TTY) for Hyprland
    greetd = {
      enable = true;
      settings.default_session = {
        user = "greeter";
        command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd start-hyprland";
      };
    };

    # Enable GNOME keyring for secrets
    gnome.gnome-keyring.enable = true;

    # Enable GVFS for trash and other virtual filesystems
    gvfs.enable = true;

    # Thumbnail service
    tumbler.enable = true;
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
  security = {
    polkit.enable = true;
    pam.services.login.enableGnomeKeyring = true;
    pam.services.greetd.enableGnomeKeyring = true;
  };

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

  # Fcitx5 input method with Vietnamese support
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5 = {
      waylandFrontend = true;
      addons = with pkgs; [
        qt6Packages.fcitx5-unikey # Vietnamese input
        fcitx5-gtk # GTK integration
        qt6Packages.fcitx5-configtool # Configuration tool
      ];
    };
  };

  # Environment variables for input method
  environment.sessionVariables = {
    # GTK_IM_MODULE = "fcitx";
    QT_IM_MODULE = "fcitx";
    XMODIFIERS = "@im=fcitx";
    SDL_IM_MODULE = "fcitx";
    GLFW_IM_MODULE = "ibus"; # For some apps that don't support fcitx directly
  };
}
