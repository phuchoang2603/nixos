{ pkgs, ... }:

{
  security.rtkit.enable = true;
  services = {
    # Audio - PipeWire
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
      wireplumber.enable = true;
    };

    # Bluetooth
    blueman.enable = true;

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

    # Game streaming server
    sunshine = {
      enable = true;
      autoStart = true;
      openFirewall = true;
    };

    # Tailscale VPN
    tailscale = {
      enable = true;
      useRoutingFeatures = "client";
    };

    # Avahi for network discovery
    avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
    };

    # USB automounting
    udisks2.enable = true;

    # Set up udev rules for uinput
    udev.extraRules = ''
      KERNEL=="uinput", GROUP="input", MODE="0660"
    '';

    # Firmware updates
    fwupd.enable = true;

    # SSH (optional - enable if needed)
    openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = true;
        PermitRootLogin = "no";
      };
    };
  };

  programs = {
    # Enable dconf for GTK settings
    dconf.enable = true;

    # Enable Hyprland for system-wide
    hyprland = {
      enable = true;
      xwayland.enable = true;
    };
  };

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

  # Bluetooth
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        Enable = "Source,Sink,Media,Socket";
        Experimental = true;
      };
    };
  };

  # Docker
  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
    autoPrune = {
      enable = true;
      dates = "weekly";
    };
  };
}
