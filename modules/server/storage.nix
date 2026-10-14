{ config, ... }:

let
  inherit (import ./lib.nix) nfsServer appdata media;
in
{
  services.openiscsi = {
    enable = true;
    enableAutoLoginOut = true;
    discoverPortal = "${nfsServer}:3260";
    name = "iqn.2026-10.local.nixos:${config.networking.hostName}";
  };

  fileSystems = {
    ${appdata} = {
      device = "/dev/disk/by-uuid/183ab230-9ac0-46e8-85b9-5a64ef7bcf96";
      fsType = "ext4";
      options = [
        "_netdev"
        "x-systemd.requires=iscsi.service"
      ];
    };
    ${media} = {
      device = "${nfsServer}:${media}";
      fsType = "nfs";
      options = [
        "nofail"
        "x-systemd.automount"
      ];
    };
  };
}
