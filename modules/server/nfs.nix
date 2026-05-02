{
  boot = {
    supportedFilesystems = [ "nfs" ];
  };

  services.rpcbind.enable = true;

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
    "/mnt/storage/iso" = {
      device = "10.69.1.102:/mnt/storage/iso";
      fsType = "nfs";
      options = [
        "defaults"
        "_netdev"
        "nofail"
      ];
    };

  };
}
