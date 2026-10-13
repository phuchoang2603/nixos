{ ... }:

let
  inherit (import ./lib.nix) nfsServer appdata media;

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
    ${appdata} = {
      device = "${nfsServer}:${appdata}";
      fsType = "nfs";
      options = nfsMountOptions;
    };
    ${media} = {
      device = "${nfsServer}:${media}";
      fsType = "nfs";
      options = nfsMountOptions;
    };
  };
}
