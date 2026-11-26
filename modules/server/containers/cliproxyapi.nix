{
  lab,
  pkgs,
  ...
}:

let
  data = "${lab.appdata}/cliproxyapi";
  zenProxy = pkgs.fetchFromGitHub {
    owner = "12errh";
    repo = "zen-proxy";
    rev = "511ade19966e52a5ec862f4355b16026ca6862db";
    hash = "sha256-Ea6/b4L/4x31fNhT3sHy+FWKlyrcqwveKjQgSjzzefk=";
  };
in
{
  systemd.tmpfiles.rules = [
    "d ${data} 0755 root root -"
    "d ${data}/auths 0700 root root -"
    "d ${data}/logs 0755 root root -"
    "d ${data}/plugins 0755 root root -"
  ];

  virtualisation.oci-containers.containers.zen-proxy = lab.mkContainer {
    image = "oven/bun:1";
    entrypoint = "bun";
    cmd = [ "/app/zen-proxy.mjs" ];
    volumes = [ "${zenProxy}:/app:ro" ];
    environment = {
      HOST = "0.0.0.0";
      PORT = "8789";
      AUTO_SYNC = "0";
      ZEN_PROXY_CONFIG = "/tmp/zen-proxy.json";
    };
  };

  virtualisation.oci-containers.containers.cli-proxy-api = lab.mkContainer {
    image = "eceasy/cli-proxy-api:latest";
    dependsOn = [ "zen-proxy" ];
    cmd = [
      "./CLIProxyAPI"
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
    environment.OPENCODE_BASE_URL = "http://zen-proxy:8789";
    traefik = {
      name = "cliproxyapi";
      port = 8317;
    };
  };
}
