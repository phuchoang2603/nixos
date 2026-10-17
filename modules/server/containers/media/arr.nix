{
  lab,
  lib,
  pkgs,
  ...
}:

let
  uid = "1000";
  gid = "100";
  apps = {
    radarr = {
      image = "lscr.io/linuxserver/radarr:latest";
      port = 7878;
    };
    sonarr = {
      image = "lscr.io/linuxserver/sonarr:latest";
      port = 8989;
    };
    # Lidarr (plugins-capable nightly) for catalog/wanted lists. Pair with Tubifarry
    # in the UI for Soulseek via slskd, plus optional YouTube and lyrics helpers.
    # Shared `/downloads` with slskd so Lidarr can import without remote-path mapping.
    lidarr = {
      # 3.1.6+ on nightly/develop includes plugin support; Tubifarry 2.3 needs >= 3.1.6.0.
      image = "ghcr.io/hotio/lidarr:nightly";
      port = 8686;
      extraVolumes = [
        "${lab.media}/music:/music:rw"
        "${lab.appdata}/slskd/downloads:/downloads:rw"
      ];
    };
    chaptarr = {
      image = "chaptarr/chaptarr:latest";
      port = 8789;
    };
    prowlarr = {
      image = "lscr.io/linuxserver/prowlarr:latest";
      port = 9696;
    };
  };
  mediaContainers = [
    "radarr"
    "sonarr"
    "chaptarr"
    "lidarr"
    "qbittorrent"
    "jellyfin"
  ];
  mediaDirectories = map (directory: "${lab.media}/${directory}") [
    "movies"
    "tv"
    "music"
    "books"
    "audiobooks"
    "downloads"
    "downloads/torrents"
    "downloads/torrents/incomplete"
  ];
in
{
  systemd.tmpfiles.rules = lib.concatMap (name: [
    "d ${lab.appdata}/${name} 0750 ${uid} ${gid} -"
    "d ${lab.appdata}/${name}/config 0750 ${uid} ${gid} -"
  ]) (builtins.attrNames apps);

  systemd.services = {
    docker-media-directories = {
      description = "Prepare media libraries and torrent download directories";
      unitConfig.RequiresMountsFor = [ lab.media ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        User = uid;
        Group = gid;
        UMask = "0002";
        ExecStart = "${pkgs.coreutils}/bin/mkdir -p -m 2775 ${lib.escapeShellArgs mediaDirectories}";
      };
    };
  }
  // lib.genAttrs (map (name: "docker-${name}") mediaContainers) (_: {
    after = [ "docker-media-directories.service" ];
    requires = [ "docker-media-directories.service" ];
  });

  virtualisation.oci-containers.containers = lib.mapAttrs (
    name: app:
    lab.mkContainer {
      inherit (app) image;
      environment = {
        PUID = uid;
        PGID = gid;
        UMASK = "002";
      };
      volumes = [
        "${lab.appdata}/${name}/config:/config:rw"
      ]
      ++ lib.optional (name != "prowlarr") "${lab.media}:/data:rw"
      ++ (app.extraVolumes or [ ]);
      traefik = {
        inherit name;
        inherit (app) port;
      };
    }
  ) apps;
}
