{
  lab,
  lib,
  pkgs,
  ...
}:

let
  state = "${lab.appdata}/siyuan";
  uid = "1000";
  gid = "100";
in
{
  systemd.tmpfiles.rules = [
    "d ${state} 0700 ${uid} ${gid} -"
    "d ${state}/workspace 0700 ${uid} ${gid} -"
    "d ${state}/backups 0700 ${uid} ${gid} -"
  ];

  virtualisation.oci-containers.containers.siyuan = lab.mkContainer {
    image = "b3log/siyuan:v3.8.7@sha256:aced5ce847dc0a6bd33033176533e7c0954a0f043c95806f6831b7a351a952c9";
    cmd = [ "serve" ];
    volumes = [ "${state}/workspace:/siyuan/workspace:rw" ];
    environment = {
      PUID = uid;
      PGID = gid;
      # Pangolin enforces authentication; a host port or Traefik route would bypass it.
      SIYUAN_ACCESS_AUTH_CODE_BYPASS = "true";
    };
    extraOptions = [
      "--health-cmd=wget -q -O /dev/null http://127.0.0.1:6806/api/system/version"
      "--health-interval=30s"
      "--health-start-period=60s"
      "--health-retries=3"
    ];
  };

  systemd.services.docker-siyuan = {
    path = [
      pkgs.coreutils
      pkgs.jq
    ];
    preStart = lib.mkBefore ''
      conf="${state}/workspace/conf/conf.json"
      if [ -f "$conf" ]; then
        temporary=$(mktemp "$(dirname "$conf")/.conf.json.XXXXXX")
        trap 'rm -f "$temporary"' EXIT
        jq '.accessAuthCode = ""' "$conf" > "$temporary"
        chmod 0600 "$temporary"
        chown ${uid}:${gid} "$temporary"
        mv "$temporary" "$conf"
      fi
    '';
  };

  systemd.services.siyuan-backup = {
    description = "Back up the complete SiYuan workspace with the application stopped";
    requires = [ "docker.service" ];
    after = [ "docker.service" ];
    unitConfig.RequiresMountsFor = [ state ];
    path = [
      pkgs.coreutils
      pkgs.findutils
      pkgs.gnutar
      pkgs.gzip
      pkgs.systemd
    ];
    serviceConfig = {
      Type = "oneshot";
      UMask = "0077";
    };
    script = ''
      set -euo pipefail
      archive="${state}/backups/workspace-$(date -u +%Y%m%dT%H%M%SZ).tar.gz"
      active=$(systemctl is-active docker-siyuan.service || true)
      if [ "$active" = active ]; then
        trap 'systemctl start docker-siyuan.service' EXIT
        systemctl stop docker-siyuan.service
      fi
      tar -czf "$archive.partial" -C ${state} workspace
      chown ${uid}:${gid} "$archive.partial"
      mv "$archive.partial" "$archive"
      find ${state}/backups -maxdepth 1 -type f -name 'workspace-*.tar.gz' -mtime +30 -delete
    '';
  };

  systemd.timers.siyuan-backup = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      RandomizedDelaySec = "30min";
      Persistent = true;
    };
  };
}
