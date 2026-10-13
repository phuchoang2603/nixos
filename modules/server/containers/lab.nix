{ lib, pkgs }:

let
  inherit (import ../lib.nix)
    appdata
    media
    secrets
    domain
    tz
    proxyNetwork
    ;
in
{
  inherit
    appdata
    media
    secrets
    domain
    tz
    proxyNetwork
    ;

  fqdn = name: "${name}.${domain}";

  # Build each recipe once, independently of container startup. Bump revision to
  # refresh upstream packages without changing the recipe. No stale-image fallback.
  mkImage =
    {
      name,
      dockerfile,
      context ? null,
      containers ? [ name ],
      revision ? 1,
    }:
    let
      tag = builtins.substring 0 16 (
        builtins.hashString "sha256" "${dockerfile}:${toString context}:${toString revision}"
      );
      image = "${name}:${tag}";
    in
    {
      inherit image;
      service = {
        description = "Prepare container image ${name}";
        after = [
          "docker.service"
          "network-online.target"
        ];
        requires = [ "docker.service" ];
        wants = [ "network-online.target" ];
        before = map (container: "docker-${container}.service") containers;
        requiredBy = map (container: "docker-${container}.service") containers;
        path = [ pkgs.docker ];
        serviceConfig = {
          Type = "oneshot";
          TimeoutStartSec = "15min";
        };
        # Leave the unit inactive after success so a later start checks for images
        # removed by pruning. Existing images never trigger a rebuild.
        script = ''
          if ! docker image inspect ${lib.escapeShellArg image} > /dev/null 2>&1; then
            docker build --pull --no-cache -t ${lib.escapeShellArg image} ${
              if context == null then "- < ${dockerfile}" else "-f ${dockerfile} ${context}"
            }
          fi
        '';
      };
    };

  # ExecStartPost keeps the database unit in "activating" until it accepts TCP
  # connections. dependsOn then also waits for readiness, not just docker run.
  postgresReady = name: database: {
    serviceConfig.TimeoutStartSec = lib.mkForce 120;
    postStart = ''
      for _ in $(seq 1 60); do
        if ${pkgs.docker}/bin/docker exec ${lib.escapeShellArg name} \
          pg_isready -h 127.0.0.1 -U ${lib.escapeShellArg database} -d ${lib.escapeShellArg database} > /dev/null 2>&1; then
          exit 0
        fi
        sleep 2
      done
      echo "PostgreSQL in ${name} did not become ready" >&2
      exit 1
    '';
  };

  mkContainer =
    {
      extraOptions ? [ ],
      environment ? { },
      labels ? { },
      traefik ? null,
      ...
    }@args:
    let
      rest = builtins.removeAttrs args [
        "extraOptions"
        "environment"
        "labels"
        "traefik"
      ];
    in
    rest
    // {
      pull = args.pull or "always";
      networks = [ proxyNetwork ] ++ (args.networks or [ ]);
      inherit extraOptions;
      environment = {
        TZ = tz;
      }
      // environment;
      labels =
        (
          if traefik == null then
            { }
          else
            let
              name = traefik.name;
              host = traefik.host or "${name}.${domain}";
            in
            {
              "traefik.enable" = "true";
              "traefik.http.routers.${name}.rule" = "Host(`${host}`)";
              "traefik.http.routers.${name}.entrypoints" = "websecure";
              "traefik.http.routers.${name}.tls" = "true";
              "traefik.http.routers.${name}.tls.certresolver" = "letsencrypt";
              "traefik.http.services.${name}.loadbalancer.server.port" = toString traefik.port;
            }
        )
        // labels;
    };
}
