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
      CANTINARR_PUSH_GATEWAY_URL = "https://push.cantinarr.com";
      CANTINARR_MEDIA_ROOTS = "/media";
      CANTINARR_AI_PROVIDER = "local_openai";
      CANTINARR_AI_MODEL = "gemini-3.8-flash";
    };
    volumes = [
      "${state}/config:/config:rw"
      "${lab.media}:/media:ro"
    ];
    traefik = {
      name = "cantinarr";
      port = 8585;
    };
  };
}
