{
  pkgs,
  lib,
  config,
  ...
}:

let
  # Directories for bisync (OneDrive only)
  bisyncDirs = [
    "Pictures"
    "Documents"
    "Music"
    "Videos"
  ];

  # Remote names for mounting
  mountRemotes = [
    "onedrive"
    "onedrive-usf"
    "gdrive"
  ];

  home = config.home.homeDirectory;
  configPath = "${home}/.config/rclone/rclone.conf";

  # Helper to generate bisync service names
  toBisyncName = dir: "rclone-bisync-${lib.replaceStrings [ " " ] [ "-" ] dir}";
  # Helper to generate mount service names
  toMountName = remote: "rclone-mount-${remote}";
in
{
  config = lib.mkIf pkgs.stdenv.isLinux {
    home.packages = [ pkgs.rclone ];

    systemd.user.services =
      # Bisync Services (OneDrive)
      (lib.genAttrs (map toBisyncName bisyncDirs) (
        name:
        let
          dir = lib.removePrefix "rclone-bisync-" name;
          localPath = "${home}/${dir}";
          remotePath = "onedrive:Library/${dir}";
        in
        {
          Unit = {
            Description = "Rclone Bisync for ${dir} (OneDrive)";
            Documentation = [ "man:rclone(1)" ];
            After = [ "network-online.target" ];
            Wants = [ "network-online.target" ];
          };
          Service = {
            Type = "oneshot";
            ExecStart = pkgs.writeShellScript "${name}-wrapper" ''
              mkdir -p "${localPath}"
              CACHE_DIR="$HOME/.cache/rclone/bisync"
              if [ ! -d "$CACHE_DIR" ] || [ -z "$(ls -A "$CACHE_DIR")" ]; then
                echo "No prior sync history found for ${dir}. Running initial --resync..."
                ${pkgs.rclone}/bin/rclone bisync "${remotePath}" "${localPath}" \
                  --resync \
                  --create-empty-src-dirs \
                  --compare size,modtime,checksum \
                  --slow-hash-sync-only \
                  --config "${configPath}" -v
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
                  --config "${configPath}" -v
              fi
            '';
          };
        }
      ))
      # Mount Services (Multiple Remotes)
      // (lib.genAttrs (map toMountName mountRemotes) (
        name:
        let
          remote = lib.removePrefix "rclone-mount-" name;
          mountPoint = "${home}/mnt/${remote}";
        in
        {
          Unit = {
            Description = "Rclone Mount - ${remote}";
            After = [ "network-online.target" ];
            Wants = [ "network-online.target" ];
          };
          Service = {
            Type = "simple";
            ExecStartPre = "/run/current-system/sw/bin/mkdir -p ${mountPoint}";
            ExecStart = "${pkgs.rclone}/bin/rclone mount ${remote}: ${mountPoint} --config=${configPath} --vfs-cache-mode full --vfs-cache-max-age 675h --allow-other --allow-non-empty --dir-cache-time 672h";
            ExecStop = "/run/current-system/sw/bin/fusermount -u ${mountPoint}";
            Restart = "always";
            RestartSec = 10;
          };
          Install = {
            WantedBy = [ "default.target" ];
          };
        }
      ));

    systemd.user.timers = lib.genAttrs (map toBisyncName bisyncDirs) (_name: {
      Unit.Description = "Run Rclone Bisync timer";
      Timer = {
        OnCalendar = "*-*-* 00/4:00:00";
        Persistent = true;
      };
      Install.WantedBy = [ "timers.target" ];
    });
  };
}
