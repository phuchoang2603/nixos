{ lab, ... }:

let
  uid = "1000";
  gid = "100";
  state = "${lab.appdata}/cantinarr";
in
{
  systemd.tmpfiles.rules = [
    "d ${state} 0750 ${uid} ${gid} -"
    "d ${state}/config 0750 ${uid} ${gid} -"
  ];

  virtualisation.oci-containers.containers.cantinarr = lab.mkContainer {
    image = "ghcr.io/windoze95/cantinarr:latest";
    environment = {
      PUID = uid;
      PGID = gid;
      CANTINARR_SERVER_NAME = "Home media";
      CANTINARR_ARR_CALLBACK_URL = "http://cantinarr:8585";
      CANTINARR_OAUTH_ISSUER = "https://${lab.fqdn "cantinarr"}";
    };
    volumes = [ "${state}/config:/config:rw" ];
    traefik = {
      name = "cantinarr";
      port = 8585;
    };
  };
}
