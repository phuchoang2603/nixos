{ lab, ... }:

let
  data = "${lab.appdata}/executor";
in
{
  systemd.tmpfiles.rules = [ "d ${data}/v2 0700 root root -" ];

  virtualisation.oci-containers.containers.executor = lab.mkContainer {
    image = "ghcr.io/usefulsoftwareco/executor-selfhost:2.0.0-beta.37";
    volumes = [ "${data}/v2:/app/data:rw" ];
    environment = {
      BETTER_AUTH_URL = "https://${lab.fqdn "mcp"}";
      EXECUTOR_APPS_ALLOW_PRIVATE_FETCH = "true";
    };
    extraOptions = [ "--init" ];
    traefik = {
      name = "mcp";
      port = 4400;
    };
  };
}
