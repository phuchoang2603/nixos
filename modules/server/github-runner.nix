{
  config,
  pkgs,
  lib,
  ...
}:

let
  runnerUser = "github-runner";
  secretsDir = "/mnt/storage/appdata/secrets";
in
{
  users.users.${runnerUser} = {
    isSystemUser = true;
    group = runnerUser;
    description = "GitHub Actions self-hosted runner";
  };

  users.groups.${runnerUser} = { };

  security.sudo.extraRules = [
    {
      users = [ runnerUser ];
      commands = [
        {
          command = "${pkgs.nh}/bin/nh";
          options = [
            "NOPASSWD"
            "SETENV"
          ];
        }
      ];
    }
  ];

  services.github-runners.nixos-server = {
    enable = true;
    name = "nixos-server";
    url = "https://github.com/phuchoang2603/nixos";
    tokenFile = "${secretsDir}/github-runner.token";
    replace = true;
    extraLabels = [ "nixos-server" ];
    user = runnerUser;
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
