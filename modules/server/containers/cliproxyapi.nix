{
  lab,
  lib,
  pkgs,
  ...
}:

let
  data = "${lab.appdata}/cliproxyapi";
  headroomData = "${lab.appdata}/headroom";
  headroomArchive = pkgs.fetchurl {
    url = "https://github.com/frankyw/cliproxyapi-headroom/releases/download/v0.6.0/headroom_0.6.0_linux_amd64.zip";
    hash = "sha256-gg/AeFkbEpUluHLR9gVEKhE4IuZwREbr7+gIO8jTiRw=";
  };
  headroomPlugin = pkgs.runCommand "headroom-v0.6.0.so" { nativeBuildInputs = [ pkgs.unzip ]; } ''
    unzip -p ${headroomArchive} headroom.so > "$out"
  '';
  python = pkgs.python3.withPackages (ps: [ ps.pyyaml ]);
  configureHeadroom = pkgs.writeText "configure-cliproxyapi-headroom.py" ''
    import os
    from pathlib import Path
    import shutil
    import sys
    import yaml

    path = Path(sys.argv[1])
    original = path.read_text()
    config = yaml.safe_load(original)
    plugins = config.setdefault("plugins", {})
    plugins["enabled"] = True
    plugins.setdefault("dir", "/CLIProxyAPI/plugins")
    plugins.setdefault("configs", {})["headroom"] = {
        "enabled": True,
        "priority": 10,
        "endpoint": "http://headroom:8787/v1/compress",
        "stats_path": "/CLIProxyAPI/plugins/data/headroom/stats.json",
        "timeout_ms": 10000,
        "min_chars": 512,
        "target_ratio": 0.5,
        "compress_user_messages": False,
    }
    updated = yaml.safe_dump(config, sort_keys=False)
    if yaml.safe_load(original) != config:
        backup = path.with_name(path.name + ".before-headroom")
        if not backup.exists():
            shutil.copy2(path, backup)
        temporary = path.with_name(path.name + ".headroom-tmp")
        with temporary.open("w") as output:
            os.chmod(temporary, 0o600)
            output.write(updated)
        temporary.replace(path)
  '';

  # MIT fork of CLIProxyAPI with a dedicated OpenCode Zen/Go executor (free-tier
  # identity + tool shaping). Prefer this over opaque third-party patches.
  plusVersion = "8.0.31-1";
  plusTarball = "CLIProxyAPI_${plusVersion}_linux_amd64.tar.gz";
  plusUrl = "https://github.com/jc01rho/CLIProxyAPIPlus/releases/download/v${plusVersion}/${plusTarball}";

  localImage = lab.mkImage {
    name = "cli-proxy-api-plus";
    # Image name differs from the oci-container unit name.
    containers = [ "cli-proxy-api" ];
    revision = 1;
    dockerfile = pkgs.writeText "cli-proxy-api-plus.Dockerfile" ''
      FROM debian:bookworm-slim
      RUN apt-get update \
        && apt-get install -y --no-install-recommends ca-certificates tzdata curl \
        && rm -rf /var/lib/apt/lists/*
      WORKDIR /CLIProxyAPI
      RUN curl -fsSL -o /tmp/plus.tar.gz ${plusUrl} \
        && tar -xzf /tmp/plus.tar.gz -C /CLIProxyAPI \
        && rm /tmp/plus.tar.gz \
        && ln -sf cli-proxy-api CLIProxyAPI \
        && test -x ./cli-proxy-api \
        && ./cli-proxy-api -h 2>&1 | grep -q 'CLIProxyAPI Version'
      EXPOSE 8317
    '';
  };
in
{
  systemd.tmpfiles.rules = [
    "d ${data} 0755 root root -"
    "d ${data}/auths 0700 root root -"
    "d ${data}/logs 0755 root root -"
    "d ${data}/plugins 0755 root root -"
    "d ${headroomData}/data 0755 root root -"
    "d ${headroomData}/cache 0755 root root -"
  ];

  systemd.services.docker-image-cli-proxy-api = localImage.service;
  systemd.services.docker-cli-proxy-api.preStart = lib.mkBefore ''
    install -d -m 0755 ${data}/plugins/linux/amd64
    install -m 0644 ${headroomPlugin} ${data}/plugins/linux/amd64/headroom-v0.6.0.so.tmp
    mv -f ${data}/plugins/linux/amd64/headroom-v0.6.0.so.tmp ${data}/plugins/linux/amd64/headroom-v0.6.0.so
    ${python}/bin/python ${configureHeadroom} ${data}/config/config.yaml
  '';

  virtualisation.oci-containers.containers.headroom = lab.mkContainer {
    image = "ghcr.io/headroomlabs-ai/headroom:0.41.0";
    cmd = [
      "--host"
      "0.0.0.0"
      "--port"
      "8787"
    ];
    environment = {
      HOME = "/home/nonroot";
      HEADROOM_HOST = "0.0.0.0";
      HEADROOM_COMPRESS_ALLOW_REMOTE = "1";
      HEADROOM_ALLOW_UNAUTHENTICATED_BIND = "1";
      HEADROOM_WORKSPACE_DIR = "/home/nonroot/.headroom";
      HEADROOM_CONFIG_DIR = "/home/nonroot/.headroom/config";
      HF_HOME = "/home/nonroot/.cache/huggingface";
      HEADROOM_TELEMETRY = "off";
      HEADROOM_BEACON = "off";
      DO_NOT_TRACK = "1";
    };
    volumes = [
      "${headroomData}/data:/home/nonroot/.headroom:rw"
      "${headroomData}/cache:/home/nonroot/.cache:rw"
    ];
  };

  virtualisation.oci-containers.containers.cli-proxy-api = lab.mkContainer {
    inherit (localImage) image;
    pull = "never";
    dependsOn = [ "headroom" ];
    cmd = [
      "./cli-proxy-api"
      "-config"
      "/config/config.yaml"
    ];
    volumes = [
      "${data}/config:/config:rw"
      "${data}/auths:/root/.cli-proxy-api:rw"
      "${data}/logs:/CLIProxyAPI/logs:rw"
      "${data}/plugins:/CLIProxyAPI/plugins:rw"
    ];
    environmentFiles = [ "${lab.secrets}/cliproxyapi.env" ];
    traefik = {
      name = "cliproxyapi";
      port = 8317;
    };
  };
}
