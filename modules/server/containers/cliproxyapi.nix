{ lab, pkgs, ... }:

let
  data = "${lab.appdata}/cliproxyapi";

  # MIT fork of CLIProxyAPI with a dedicated OpenCode Zen/Go executor (free-tier
  # identity + tool shaping). Prefer this over opaque third-party patches.
  plusVersion = "8.0.31-1";
  plusTarball = "CLIProxyAPI_${plusVersion}_linux_amd64.tar.gz";
  plusUrl = "https://github.com/jc01rho/CLIProxyAPIPlus/releases/download/v${plusVersion}/${plusTarball}";

  localImage = lab.mkImage {
    name = "cli-proxy-api-plus";
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
  ];

  systemd.services.docker-image-cli-proxy-api = localImage.service;

  virtualisation.oci-containers.containers.cli-proxy-api = lab.mkContainer {
    inherit (localImage) image;
    pull = "never";
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
