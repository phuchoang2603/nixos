{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (import ./lib.nix) proxyNetwork appdata;
in
{
  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
    # --all removes every image no container uses, not just untagged ones; the images
    # services run on are pulled (or built) again when they start.
    autoPrune = {
      enable = true;
      dates = "daily";
      flags = [ "--all" ];
    };
  };

  virtualisation.oci-containers.backend = "docker";

  systemd.services = {
    docker-network-proxy = {
      description = "Prepare Docker ${proxyNetwork} network and application directories";
      wantedBy = [ "multi-user.target" ];
      after = [ "docker.service" ];
      requires = [ "docker.service" ];
      unitConfig.RequiresMountsFor = [ appdata ];
      preStart = "${pkgs.systemd}/bin/systemd-tmpfiles --create --prefix=${appdata}";
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
  // lib.mapAttrs' (
    name: container:
    let
      paths =
        map (volume: builtins.head (lib.splitString ":" volume)) container.volumes
        ++ container.environmentFiles;
    in
    {
      name = "docker-${name}";
      value = {
        after = [ "docker-network-proxy.service" ];
        requires = [ "docker-network-proxy.service" ];
        # Recreate containers on a normal switch when their encrypted secrets change.
        restartTriggers = map (secret: secret.file) (
          lib.filter (secret: builtins.elem secret.path paths) (builtins.attrValues config.age.secrets)
        );
        # Bind mounts and environment files carry their own storage dependencies.
        # Named Docker volumes do not refer to host paths.
        unitConfig.RequiresMountsFor = lib.unique (lib.filter (lib.hasPrefix "/") paths);
      };
    }
  ) config.virtualisation.oci-containers.containers;
}
