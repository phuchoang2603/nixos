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
  agy =
    pkgs.runCommand "agy-1.5.17"
      {
        src = pkgs.fetchurl {
          url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.5.17-4823843970351104/linux-x64/cli_linux_x64.tar.gz";
          sha512 = "71a967aa16e0ab5d87196bcd6772130bdab55b2fd768cd24d21b1da401ff9f60280b976cad3dc14a2d646233b0eaf8caf87c490eed73044d54550cbb3d8d67d2";
        };
        dontFixup = true;
      }
      ''
        mkdir -p $out
        tar -xzf $src -C $out
      '';
  agyPlugin =
    pkgs.runCommand "cliproxy-antigravity-0.7.1"
      {
        src = pkgs.fetchurl {
          url = "https://github.com/adeebahmad01/cliproxy-antigravity/releases/download/v0.7.1/cliproxy-antigravity_0.7.1_linux_amd64.zip";
          sha256 = "408ca76613e05d4f50a768a12ae48ba2a8f98c0088f5112651f8eb6a270398fd";
        };
        nativeBuildInputs = [ pkgs.unzip ];
        dontFixup = true;
      }
      ''
        mkdir -p $out
        unzip $src -d $out
      '';
in
{
  systemd.tmpfiles.rules = [
    "d ${data} 0755 root root -"
    "d ${data}/auths 0700 root root -"
    "d ${data}/logs 0755 root root -"
    "d ${data}/plugins 0755 root root -"
    "d ${data}/agy-accounts 0700 root root -"
    "d ${data}/agy-config 0700 root root -"
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
      "${data}/agy-accounts:/root/.agy-accounts:rw"
      "${data}/agy-config:/root/.config/cliproxy-antigravity:rw"
      "${agy}/antigravity:/usr/local/bin/agy:ro"
      "${agyPlugin}/cliproxy-antigravity.so:/CLIProxyAPI/plugins/linux/amd64/cliproxy-antigravity.so:ro"
    ];
    environmentFiles = [ "${lab.secrets}/cliproxyapi.env" ];
    environment.OPENCODE_BASE_URL = "http://zen-proxy:8789";
    traefik = {
      name = "cliproxyapi";
      port = 8317;
    };
  };
}
