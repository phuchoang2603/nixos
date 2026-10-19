{ lab, ... }:

let
  state = "${lab.appdata}/siyuan";
  uid = "1000";
  gid = "100";
in
{
  systemd.tmpfiles.rules = [
    "d ${state} 0700 ${uid} ${gid} -"
    "d ${state}/workspace 0700 ${uid} ${gid} -"
  ];

  virtualisation.oci-containers.containers.siyuan = lab.mkContainer {
    image = "b3log/siyuan:v3.8.7@sha256:aced5ce847dc0a6bd33033176533e7c0954a0f043c95806f6831b7a351a952c9";
    cmd = [ "serve" ];
    volumes = [ "${state}/workspace:/siyuan/workspace:rw" ];
    environment = {
      PUID = uid;
      PGID = gid;
      SIYUAN_OPENAI_API_BASE_URL = "http://cli-proxy-api:8317/v1";
      SIYUAN_OPENAI_API_MODEL = "gpt-6.1-sol";
      SIYUAN_OPENAI_API_KEY = "cliproxyapi";
      # Pangolin enforces authentication; a host port or Traefik route would bypass it.
      SIYUAN_ACCESS_AUTH_CODE_BYPASS = "true";
    };
  };
}
