{
  pkgs,
  lib,
  config,
  ...
}:

let
  cfg = config.my.rcloneBisync;

  mkServiceName = dir: "rclone-bisync-${lib.replaceStrings [ " " ] [ "-" ] dir}";

  mkService =
    dir:
    let
      serviceName = mkServiceName dir;
      remotePath = "${cfg.remote}:${cfg.libraryBase}/${dir}";
      localPath = "${config.home.homeDirectory}/${dir}";

      execStartScript = pkgs.writeShellScript "rclone-bisync-${dir}-wrapper" ''
        CACHE_DIR="$HOME/.cache/rclone/bisync"
        # Rclone creates cache files with underscores replacing slashes and colons
        # This is a simplified check; if the directory is empty, we resync.
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
        OnCalendar = cfg.timerOnCalendar;
        Persistent = true;
      };
      Install = {
        WantedBy = [ "timers.target" ];
      };
    };
in
{
  options.my.rcloneBisync = {
    enable = lib.mkEnableOption "rclone bisync timers";

    remote = lib.mkOption {
      type = lib.types.str;
      default = "onedrive";
      description = "Rclone remote name to sync against.";
    };

    libraryBase = lib.mkOption {
      type = lib.types.str;
      default = "Library";
      description = "Remote base path for OneDrive libraries.";
    };

    dirs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "Pictures"
        "Documents"
        "Music"
        "Videos"
      ];
      description = "Directories to bisync relative to the home directory.";
    };

    timerOnCalendar = lib.mkOption {
      type = lib.types.str;
      default = "*-*-* 00/4:00:00";
      description = "Systemd OnCalendar schedule for bisync timers.";
    };

    extraArgs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Extra arguments appended to the rclone bisync command.";
    };
  };

  config = lib.mkIf (cfg.enable && pkgs.stdenv.isLinux) {
    home.packages = [ pkgs.rclone ];

    systemd.user.services = lib.listToAttrs (map mkService cfg.dirs);
    systemd.user.timers = lib.listToAttrs (map mkTimer cfg.dirs);
  };
}
