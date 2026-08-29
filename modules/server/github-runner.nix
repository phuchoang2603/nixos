{
  pkgs,
  lib,
  ...
}:

let
  secretsDir = "/mnt/storage/appdata/secrets";
in
{
  services.github-runners.nixos-server = {
    enable = true;
    name = "nixos-server";
    url = "https://github.com/phuchoang2603/nixos";
    tokenFile = "${secretsDir}/github-runner.token";
    replace = true;
    extraLabels = [ "nixos-server" ];
    user = "root";
    extraPackages = with pkgs; [
      nh
      git
      nix
    ];
    serviceOverrides = {
      After = [
        "network-online.target"
        "nfs-storage-mount.service"
      ];
      Requires = [ "nfs-storage-mount.service" ];
    };
  };
}
