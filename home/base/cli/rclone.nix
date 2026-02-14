{
  pkgs,
  lib,
  config,
  ...
}:

let
  mkServiceName = dir: "rclone-bisync-${lib.replaceStrings [ " " ] [ "-" ] dir}";

  mkService =
    dir:
    let
      serviceName = mkServiceName dir;
      remotePath = "onedrive:Library/${dir}";
      localPath = "${config.home.homeDirectory}/${dir}";

      execStartScript = pkgs.writeShellScript "rclone-bisync-${dir}-wrapper" ''
        CACHE_DIR="$HOME/.cache/rclone/bisync"
        mkdir -p "${localPath}"
        if [ ! -d "$CACHE_DIR" ] || [ -z "$(ls -A "$CACHE_DIR")" ]; then
          echo "No prior sync history found for ${dir}. Running initial --resync..."
          ${pkgs.rclone}/bin/rclone bisync "${remotePath}" "${localPath}" \
            --resync \
            --create-empty-src-dirs \
            --compare size,modtime,checksum \
            --slow-hash-sync-only \
            --config "$HOME/.config/rclone/rclone.conf" -v
        else
          ${pkgs.rclone}/bin/rclone bisync "${remotePath}" "${localPath}" \
            --create-empty-src-dirs \
            --compare size,modtime,checksum \
            --slow-hash-sync-only \
            --resilient \
            --recover \
            --fix-case \
            --conflict-resolve newer \
            --conflict-loser delete \
            --check-access \
            --config "$HOME/.config/rclone/rclone.conf" -v
        fi
      '';
    in
    lib.nameValuePair serviceName {
      Unit = {
        Description = "Rclone Bisync for ${dir} (OneDrive)";
        Documentation = [ "man:rclone(1)" ];
        AssertPathIsDirectory = localPath;
        After = [ "network-online.target" ];
        Wants = [ "network-online.target" ];
      };
      Service = {
        Type = "oneshot";
        ExecStart = "${execStartScript}";
      };
    };

  mkTimer =
    dir:
    let
      serviceName = mkServiceName dir;
    in
    lib.nameValuePair serviceName {
      Unit = {
        Description = "Run Rclone Bisync for ${dir}";
        Requires = [ "${serviceName}.service" ];
      };
      Timer = {
        OnCalendar = "*-*-* 00/4:00:00";
        Persistent = true;
      };
      Install = {
        WantedBy = [ "timers.target" ];
      };
    };

  dirs = [
    "Pictures"
    "Documents"
    "Music"
    "Videos"
  ];

  mountPath = "mnt/onedrive";
in
{
  config = lib.mkIf pkgs.stdenv.isLinux {
    home.packages = [ pkgs.rclone ];

    systemd.user.services = (lib.listToAttrs (map mkService dirs)) // {
      rclone-mount-onedrive = {
        Unit = {
          Description = "Rclone Mount - OneDrive";
          After = [ "network-online.target" ];
          Wants = [ "network-online.target" ];
        };
        Service = {
          Type = "simple";
          ExecStartPre = "/run/current-system/sw/bin/mkdir -p ${config.home.homeDirectory}/${mountPath}";
          ExecStart = "${pkgs.rclone}/bin/rclone mount onedrive: ${config.home.homeDirectory}/${mountPath} --config=${config.home.homeDirectory}/.config/rclone/rclone.conf --vfs-cache-mode full --vfs-cache-max-age 675h --allow-other --allow-non-empty --dir-cache-time 672h";
          ExecStop = "/run/current-system/sw/bin/fusermount -u ${config.home.homeDirectory}/${mountPath}";
          Restart = "always";
          RestartSec = 10;
        };
        Install = {
          WantedBy = [ "default.target" ];
        };
      };
    };

    systemd.user.timers = lib.listToAttrs (map mkTimer dirs);
  };
}
