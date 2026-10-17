{ lab, ... }:

# Lidarr (plugins-capable nightly) for catalog/wanted lists. Pair with Tubifarry
# in the UI for Soulseek via slskd, plus optional YouTube and lyrics helpers.
# Shared `/downloads` with slskd so Lidarr can import without remote-path mapping.
let
  uid = "1000";
  gid = "100";
  state = "${lab.appdata}/lidarr";
  slskdDownloads = "${lab.appdata}/slskd/downloads";
in
{
  systemd.tmpfiles.rules = [
    "d ${state} 0750 ${uid} ${gid} -"
    "d ${state}/config 0750 ${uid} ${gid} -"
  ];

  virtualisation.oci-containers.containers.lidarr = lab.mkContainer {
    # 3.1.6+ on nightly/develop includes plugin support; Tubifarry 2.3 needs >= 3.1.6.0.
    image = "ghcr.io/hotio/lidarr:nightly";
    environment = {
      PUID = uid;
      PGID = gid;
      UMASK = "002";
    };
    volumes = [
      "${state}/config:/config:rw"
      "${lab.media}/music:/music:rw"
      "${slskdDownloads}:/downloads:rw"
    ];
    traefik = {
      name = "lidarr";
      port = 8686;
    };
  };
}
