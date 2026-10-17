{ lab, ... }:

# Lidarr (plugins-capable nightly) for catalog/wanted lists. Pair with Tubifarry
# in the UI for YouTube Music searches, downloads, and lyrics.
let
  uid = "1000";
  gid = "100";
  state = "${lab.appdata}/lidarr";
in
{
  systemd.tmpfiles.rules = [
    "d ${state} 0750 ${uid} ${gid} -"
    "d ${state}/config 0750 ${uid} ${gid} -"
    "d ${state}/config/downloads/youtube 0750 ${uid} ${gid} -"
  ];

  virtualisation.oci-containers.containers.lidarr = lab.mkContainer {
    # 3.1.6+ on nightly/develop includes plugin support; Tubifarry 2.3 needs >= 3.1.6.0.
    image = "ghcr.io/hotio/lidarr:nightly";
    dependsOn = [ "lidarr-youtube-session" ];
    environment = {
      PUID = uid;
      PGID = gid;
      UMASK = "002";
    };
    volumes = [
      "${state}/config:/config:rw"
      "${lab.media}/music:/music:rw"
    ];
    traefik = {
      name = "lidarr";
      port = 8686;
    };
  };

  virtualisation.oci-containers.containers.lidarr-youtube-session = lab.mkContainer {
    image = "brainicism/bgutil-ytdlp-pot-provider@sha256:d7d34108b76e52c7d3b575fe9e797e4bf41c1b2a08f80c5292eff6f851ce8472";
    extraOptions = [ "--init" ];
  };
}
