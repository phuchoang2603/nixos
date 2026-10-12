{ lab, pkgs, ... }:

# Explo: each week it downloads ListenBrainz's recommendations for Felix (built from what he plays)
# into the music library and makes them a Jellyfin playlist. Its setup wizard writes .env, which
# starts out with the Jellyfin settings below; the ListenBrainz token and Jellyfin API key go in
# through the wizard. The web UI has no login unless UI_USERNAME and UI_PASSWORD are added to .env.
let
  uid = "1000";
  gid = "100";
  state = "/var/lib/explo";
  seed = pkgs.writeText "explo.env" ''
    DISCOVERY_SERVICE=listenbrainz
    EXPLO_SYSTEM=jellyfin
    SYSTEM_URL=http://jellyfin:8096
    SYSTEM_USERNAME=jellyfin
    LIBRARY_NAME=Music
    DOWNLOAD_SERVICES=youtube
    USE_SUBDIRECTORY=false
    PATH_TEMPLATE={{Artist}}/{{Album}}/{{File}}
    EMBED_COVER_ART=true
  '';
in
{
  systemd.tmpfiles.rules = [
    "d ${state} 0750 ${uid} ${gid} -"
    "d ${state}/config 0750 ${uid} ${gid} -"
    "C ${state}/.env 0600 ${uid} ${gid} - ${seed}"
  ];

  virtualisation.oci-containers.containers.explo = lab.mkContainer {
    image = "ghcr.io/lumepart/explo:latest";
    volumes = [
      "${state}/.env:/opt/explo/.env:rw"
      "${state}/config:/opt/explo/config:rw"
      "${lab.media}/music/explo:/data:rw"
    ];
    environment = {
      # The container starts as root to update yt-dlp, then runs Explo as this user.
      PUID = uid;
      PGID = gid;
      WEB_UI = "true";
    };
    traefik = {
      name = "explo";
      port = 7288;
    };
  };
}
