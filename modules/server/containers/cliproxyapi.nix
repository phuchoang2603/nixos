{ lab, ... }:

let
  data = "${lab.appdata}/cliproxyapi";
in
{
  systemd.tmpfiles.rules = [
    "d ${data} 0755 root root -"
    "d ${data}/auths 0700 root root -"
    "d ${data}/logs 0755 root root -"
    "d ${data}/plugins 0755 root root -"
  ];

  virtualisation.oci-containers.containers.cli-proxy-api = lab.mkContainer {
    image = "eceasy/cli-proxy-api:latest";
    volumes = [
      "${./cliproxyapi/config.yaml}:/CLIProxyAPI/config.yaml:ro"
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
