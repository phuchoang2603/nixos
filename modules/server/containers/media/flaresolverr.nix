{ lab, ... }:

let
  uid = "1000";
  gid = "100";
  state = "${lab.appdata}/flaresolverr";
in
{
  systemd.tmpfiles.rules = [
    "d ${state} 0750 ${uid} ${gid} -"
    "d ${state}/config 0750 ${uid} ${gid} -"
  ];

  virtualisation.oci-containers.containers.flaresolverr = lab.mkContainer {
    image = "ghcr.io/flaresolverr/flaresolverr:latest";
    user = "${uid}:${gid}";
    environment.LOG_LEVEL = "info";
    volumes = [ "${state}/config:/config:rw" ];
  };
}
