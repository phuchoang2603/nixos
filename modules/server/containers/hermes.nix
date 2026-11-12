{
  lab,
  lib,
  pkgs,
  ...
}:

let
  upstreamImage = "nousresearch/hermes-agent:latest";
  # The upstream image lacks libopus (Discord voice playback) and hindsight-client (the Hindsight
  # memory plugin); the container is recreated on every start, so runtime installs don't stick.
  dockerfile = pkgs.writeText "hermes-agent-local.Dockerfile" ''
    FROM ${upstreamImage}
    COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv
    RUN apt-get update \
      && apt-get install -y --no-install-recommends libopus0 \
      && rm -rf /var/lib/apt/lists/*
    RUN uv pip install --no-cache --python /opt/hermes/.venv/bin/python 'hindsight-client>=0.10.1,<1' \
      && /opt/hermes/.venv/bin/python -c 'import hindsight_client'
  '';

  localImage = lab.mkImage {
    name = "hermes-agent-local";
    inherit dockerfile;
    containers = [ "hermes" ];
  };

  # Keep persistent files owned by the desktop user.
  uid = "1000";
  gid = "100";

  state = "${lab.appdata}/hermes";

  plugins = import ./hermes/plugins { inherit pkgs; };

in
{
  # Hermes owns configuration, SOUL, skills, and native cron state here.
  systemd.tmpfiles.rules = [ "d ${state} 0700 ${uid} ${gid} -" ];

  systemd.services.docker-image-hermes = localImage.service;
  systemd.services.docker-hermes.after = [ "docker-hindsight.service" ];
  systemd.services.docker-hermes.wants = [
    "docker-hindsight.service"
  ];

  systemd.services.hermes-cdp-tunnel = {
    description = "Forward desktop Chrome CDP to Hermes loopback";
    wantedBy = [
      "docker-hermes.service"
      "docker-hermes-desktop.service"
    ];
    after = [
      "docker-hermes.service"
      "docker-hermes-desktop.service"
    ];
    bindsTo = [
      "docker-hermes.service"
      "docker-hermes-desktop.service"
    ];
    partOf = [
      "docker-hermes.service"
      "docker-hermes-desktop.service"
    ];
    startLimitIntervalSec = 0;
    serviceConfig = {
      RuntimeDirectory = "hermes-cdp-tunnel";
      RuntimeDirectoryMode = "0700";
      Restart = "always";
      RestartSec = 5;
    };
    script = ''
      printf '[hermes-desktop]:2222 %s\n' "$(cat ${lab.appdata}/hermes-desktop/ssh/host_ed25519.pub)" > "$RUNTIME_DIRECTORY/known_hosts"
      gatewayPid=$(${pkgs.docker}/bin/docker inspect --format '{{.State.Pid}}' hermes)
      desktopIp=$(${pkgs.docker}/bin/docker inspect --format '{{(index .NetworkSettings.Networks "${lab.proxyNetwork}").IPAddress}}' hermes-desktop)
      exec ${pkgs.util-linux}/bin/nsenter --target "$gatewayPid" --net -- \
        ${pkgs.openssh}/bin/ssh -F /dev/null -nNT \
        -i ${state}/.ssh/desktop_ed25519 -p 2222 \
        -o BatchMode=yes -o IdentitiesOnly=yes \
        -o StrictHostKeyChecking=yes -o 'HostKeyAlias=[hermes-desktop]:2222' \
        -o UserKnownHostsFile="$RUNTIME_DIRECTORY/known_hosts" \
        -o ExitOnForwardFailure=yes -o ConnectTimeout=10 \
        -o ServerAliveInterval=30 -o ServerAliveCountMax=3 \
        -L 127.0.0.1:9222:127.0.0.1:9222 "pn@$desktopIp"
    '';
  };

  virtualisation.oci-containers.containers.hermes = lab.mkContainer {
    inherit (localImage) image;
    pull = "never";
    # The desktop's preStart creates the SSH key Hermes logs in with.
    dependsOn = [ "hermes-desktop" ];
    cmd = [
      "gateway"
      "run"
    ];
    volumes = [
      "${state}:/opt/data:rw"
    ]
    ++ lib.mapAttrsToList (name: source: "${source}:/opt/data/plugins/${name}:ro") plugins;
    environmentFiles = [ "${lab.secrets}/hermes.env" ];
    environment = {
      PUID = uid;
      PGID = gid;
      HERMES_DASHBOARD = "1";
      HERMES_WRITE_SAFE_ROOT = "/opt/data:/home/pn";
      DISCORD_HOME_CHANNEL = "1558532114423484507";
      REALTIME_VOICE_LOG_CHANNEL = "1558532054889660416";
    };
    extraOptions = [
      "--shm-size=1g"
      "--memory=4g"
      "--cpus=2"
      "--security-opt=no-new-privileges"
    ];
    traefik = {
      name = "hermes";
      port = 9119;
    };
  };
}
