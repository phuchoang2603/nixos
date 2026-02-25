{ pkgs, ... }:

{
  services = {
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

    # SSH
    openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = true;
        PermitRootLogin = "no";
      };
    };

    # needed for NFS
    rpcbind.enable = true;
  };

  # Docker
  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
    daemon.settings.features.cdi = true;
    autoPrune = {
      enable = true;
      dates = "weekly";
    };
  };

  # NFS mounts
  fileSystems = {
    "/mnt/storage/appdata" = {
      device = "10.69.1.102:/mnt/storage/appdata";
      fsType = "nfs";
      options = [
        "defaults"
        "_netdev"
        "nofail"
      ];
    };
    "/mnt/storage/media" = {
      device = "10.69.1.102:/mnt/storage/media";
      fsType = "nfs";
      options = [
        "defaults"
        "_netdev"
        "nofail"
      ];
    };

  };
}
