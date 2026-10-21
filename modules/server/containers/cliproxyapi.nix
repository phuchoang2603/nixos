{ lab, lib, pkgs, ... }:

let
  data = "${lab.appdata}/cliproxyapi";

  kiroVersion = "0.9.13";
  kiroArchive = pkgs.fetchurl {
    url = "https://github.com/nguyenha935/kiro-cpa-plugin/releases/download/v${kiroVersion}/kiro-ha-linux-amd64.tar.gz";
    sha256 = "a5ffc6d7419ba7178216985eabc24cd180bbb97cf7289dbcf31da9d4949b5b77";
  };
  kiroPlugin = pkgs.runCommand "kiro-ha-${kiroVersion}" { } ''
    mkdir -p "$out"
    tar -xzf ${kiroArchive} -C "$out" kiro-ha.so
  '';
in
{
  systemd.tmpfiles.rules = [
    "d ${data} 0755 root root -"
    "d ${data}/auths 0700 root root -"
    "d ${data}/logs 0755 root root -"
    "d ${data}/plugins 0755 root root -"
  ];

  systemd.services.docker-cli-proxy-api.preStart = lib.mkBefore ''
    cp -an ${data}/config/config.yaml ${data}/config/config.yaml.before-kiro-ha
    ${lib.getExe pkgs.yq-go} -i '
      .plugins.enabled = true |
      .plugins.dir = "/CLIProxyAPI/plugins" |
      .plugins.configs.kiro-ha.enabled = true |
      .plugins.configs.kiro-ha.priority = 1
    ' ${data}/config/config.yaml
  '';

  virtualisation.oci-containers.containers.cli-proxy-api = lab.mkContainer {
    image = "eceasy/cli-proxy-api:v8.0.38@sha256:113a70240fb48f5c6fd674c9de40b1af4e7ff629f7acc6a412c6014ab1922daf";
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
      "${kiroPlugin}/kiro-ha.so:/CLIProxyAPI/plugins/linux/amd64/kiro-ha.so:ro"
    ];
    environmentFiles = [ "${lab.secrets}/cliproxyapi.env" ];
    traefik = {
      name = "cliproxyapi";
      port = 8317;
    };
  };
}
