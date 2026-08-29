{
  lib,
  pkgs,
  ...
}:

let
  stackEnv = {
    APPDATA = "/mnt/storage/appdata";
    MEDIA = "/mnt/storage/media";
    TZ = "America/New_York";
    SECRETS_DIR = "/mnt/storage/appdata/secrets";
  };

  stacks = {
    traefik = {
      composeFile = "compose.yml";
      after = [ ];
    };
    vault = {
      composeFile = "compose.yaml";
      after = [ "traefik" ];
    };
    vaultwarden = {
      composeFile = "compose.yml";
      after = [ "traefik" ];
    };
    karakeep = {
      composeFile = "docker-compose.yml";
      after = [ "traefik" ];
    };
    n8n = {
      composeFile = "compose.yml";
      after = [ "traefik" ];
      envFile = "${stackEnv.SECRETS_DIR}/n8n.env";
    };
    suwayomi = {
      composeFile = "compose.yml";
      after = [ "traefik" ];
    };
  };

  getStackDir =
    name:
    builtins.path {
      path = ../../stacks + "/${name}";
      name = "stack-${name}";
    };

  mkStackService =
    name: cfg:
    let
      stackDir = getStackDir name;
    in
    {
      description = "Docker stack: ${name}";
      wantedBy = [ "multi-user.target" ];
      after =
        [
          "docker.service"
          "nfs-storage-mount.service"
          "docker-network-proxy.service"
        ]
        ++ map (stack: "docker-stack-${stack}.service") cfg.after;
      requires = [
        "docker.service"
        "nfs-storage-mount.service"
      ];
      path = [ pkgs.docker ];
      environment = stackEnv // {
        COMPOSE_PROJECT_NAME = name;
      };
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        WorkingDirectory = stackDir;
        ExecStart = pkgs.writeShellScript "docker-stack-${name}-up" ''
          set -euo pipefail
          ${pkgs.docker}/bin/docker compose -f ${cfg.composeFile} up -d --remove-orphans
        '';
        ExecStop = pkgs.writeShellScript "docker-stack-${name}-down" ''
          set -euo pipefail
          ${pkgs.docker}/bin/docker compose -f ${cfg.composeFile} down
        '';
      }
      // lib.optionalAttrs (cfg.envFile or null != null) {
        EnvironmentFile = [ "-${cfg.envFile}" ];
      };
    };
in
{
  systemd.services = {
    docker-network-proxy = {
      description = "Create Docker proxy network";
      wantedBy = [ "multi-user.target" ];
      after = [ "docker.service" ];
      requires = [ "docker.service" ];
      before = map (name: "docker-stack-${name}.service") (lib.attrNames stacks);
      path = [ pkgs.docker ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeShellScript "docker-network-proxy" ''
          ${pkgs.docker}/bin/docker network inspect proxy >/dev/null 2>&1 \
            || ${pkgs.docker}/bin/docker network create proxy
        '';
      };
    };
  }
  // lib.mapAttrs' (name: cfg: {
    name = "docker-stack-${name}";
    value = mkStackService name cfg;
  }) stacks;
}
