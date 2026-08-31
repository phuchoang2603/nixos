{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (import ./lib.nix) proxyNetwork;
in
{
  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
    daemon.settings.features.cdi = true;
    autoPrune = {
      enable = true;
      dates = "weekly";
    };
  };

  virtualisation.oci-containers.backend = "docker";

  systemd.services =
    {
      docker-network-proxy = {
        description = "Create Docker ${proxyNetwork} network";
        wantedBy = [ "multi-user.target" ];
        after = [ "docker.service" ];
        requires = [ "docker.service" ];
        before = lib.mapAttrsToList (
          name: _: "docker-${name}.service"
        ) config.virtualisation.oci-containers.containers;
        path = [ pkgs.docker ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = pkgs.writeShellScript "docker-network-proxy" ''
            ${pkgs.docker}/bin/docker network inspect ${proxyNetwork} >/dev/null 2>&1 \
              || ${pkgs.docker}/bin/docker network create ${proxyNetwork}
          '';
        };
      };
    }
    // lib.mapAttrs' (name: _: {
      name = "docker-${name}";
      value = {
        after = [
          "nfs-storage-mount.service"
          "docker-network-proxy.service"
        ];
        requires = [
          "nfs-storage-mount.service"
          "docker-network-proxy.service"
        ];
      };
    }) config.virtualisation.oci-containers.containers;
}
