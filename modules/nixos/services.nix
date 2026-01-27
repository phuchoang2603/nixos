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
    blueman.enable = true;

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
