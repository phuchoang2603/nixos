{ lab, ... }:

let
  uid = "1000";
  gid = "100";
  # Jellyfin's database is SQLite, which must stay off NFS; the media stays on it, read-only.
  state = "/var/lib/jellyfin";
in
{
  systemd.tmpfiles.rules = [
    "d ${state} 0750 ${uid} ${gid} -"
    "d ${state}/config 0750 ${uid} ${gid} -"
    "d ${state}/cache 0750 ${uid} ${gid} -"
  ];

  virtualisation.oci-containers.containers.jellyfin = lab.mkContainer {
    image = "jellyfin/jellyfin:latest";
    user = "${uid}:${gid}";
    volumes = [
      "${state}/config:/config:rw"
      "${state}/cache:/cache:rw"
      "${lab.media}:/media:ro"
    ];
    environment.JELLYFIN_PublishedServerUrl = "https://${lab.fqdn "jellyfin"}";
    extraOptions = [ "--device=nvidia.com/gpu=all" ];
    traefik = {
      name = "jellyfin";
      port = 8096;
    };
  };
}
