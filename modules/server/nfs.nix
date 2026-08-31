{
  pkgs,
  ...
}:

let
  nfsServer = "10.69.1.102";

  nfsMountOptions = [
    "defaults"
    "_netdev"
    "nofail"
    # Mount on first access instead of racing dhcpcd at boot.
    "x-systemd.automount"
    "x-systemd.after=dhcpcd.service"
    "x-systemd.after=network-online.target"
  ];
in
{
  boot.supportedFilesystems = [ "nfs" ];

  services.rpcbind.enable = true;

  fileSystems = {
    "/mnt/storage/appdata" = {
      device = "${nfsServer}:/mnt/storage/appdata";
      fsType = "nfs";
      options = nfsMountOptions;
    };
    "/mnt/storage/media" = {
      device = "${nfsServer}:/mnt/storage/media";
      fsType = "nfs";
      options = nfsMountOptions;
    };
  };

  # Pre-mount NFS before app services bind data dirs.
  systemd.services.nfs-storage-mount = {
    description = "Mount NFS storage after network is ready";
    wantedBy = [ "multi-user.target" ];
    after = [
      "dhcpcd.service"
      "rpcbind.service"
      "network-online.target"
    ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "mount-nfs-storage" ''
        for _ in $(seq 1 30); do
          if ${pkgs.iputils}/bin/ping -c 1 -W 1 ${nfsServer} >/dev/null 2>&1; then
            ${pkgs.systemd}/bin/systemctl start mnt-storage-appdata.mount mnt-storage-media.mount
            exit 0
          fi
          sleep 1
        done
        echo "NFS server ${nfsServer} not reachable; skipping pre-mount"
        exit 0
      '';
    };
  };
}
