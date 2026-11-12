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
  # Both native browser tools need the sandbox's loopback CDP forwarded before discovery.
  dockerfile = pkgs.writeText "hermes-agent-local.Dockerfile" ''
    FROM ${upstreamImage}
    COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv
    RUN apt-get update \
      && apt-get install -y --no-install-recommends libopus0 \
      && rm -rf /var/lib/apt/lists/*
    RUN uv pip install --no-cache --python /opt/hermes/.venv/bin/python 'hindsight-client>=0.10.1,<1' \
      && /opt/hermes/.venv/bin/python -c 'import hindsight_client'
    COPY browser_cdp_bridge.py /opt/hermes/tools/browser_cdp_bridge.py
    COPY patch_browser.py /tmp/patch_browser.py
    RUN /opt/hermes/.venv/bin/python /tmp/patch_browser.py && rm /tmp/patch_browser.py
  '';

  localImage = lab.mkImage {
    name = "hermes-agent-local";
    inherit dockerfile;
    context = lib.fileset.toSource {
      root = ./hermes;
      fileset = lib.fileset.unions [
        ./hermes/browser_cdp_bridge.py
        ./hermes/patch_browser.py
      ];
    };
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
