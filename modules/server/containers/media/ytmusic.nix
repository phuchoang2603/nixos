{
  lib,
  pkgs,
  user,
  ...
}:

let
  inherit (import ../../lib.nix) media;
  playlistUrls = [
    "https://www.youtube.com/playlist?list=PLRvr-KNicQqY"
    "https://www.youtube.com/playlist?list=PLlDl_z3cUzHpv8DsXIYUBbRkg_IHOJA9j"
    "https://www.youtube.com/playlist?list=PLlDl_z3cUzHr9uIomVx0Mejkj3sEfSwra"
    "https://www.youtube.com/playlist?list=PLlDl_z3cUzHpWcuOBPXv4ci3Q2nXSDAF7"
  ];
in
{
  config = {
    systemd.services.yt-playlist-sync = {
      description = "Sync a YouTube playlist into the music library";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      unitConfig.RequiresMountsFor = [ "${media}/music" ];
      serviceConfig = {
        Type = "oneshot";
        User = user;
        StateDirectory = "yt-playlist-sync";
        UMask = "0002";
      };
      path = [ pkgs.yt-dlp pkgs.ffmpeg pkgs.python3 ];
      script = ''
        archive=/var/lib/yt-playlist-sync/archive.txt
        touch "$archive"
        python3 - "$archive" "${media}/music" <<'PY'
        import pathlib
        import re
        import sys

        archive = pathlib.Path(sys.argv[1])
        music = pathlib.Path(sys.argv[2])
        known = set(archive.read_text().splitlines())
        ids = {
            match.group(1)
            for path in music.rglob("*")
            if path.is_file()
            for match in [re.search(r"\[([A-Za-z0-9_-]{11})\]", path.name)]
            if match
        }
        with archive.open("a") as output:
            for video_id in sorted(ids):
                entry = f"youtube {video_id}"
                if entry not in known:
                    output.write(entry + "\n")
        PY

        for playlist in ${lib.escapeShellArgs playlistUrls}; do
          yt-dlp \
            --ignore-errors \
            --extract-audio \
            --audio-format best \
            --embed-metadata \
            --embed-thumbnail \
            --convert-thumbnails jpg \
            --download-archive /var/lib/yt-playlist-sync/archive.txt \
            --no-overwrites \
            --output '${media}/music/%(artist,creator,uploader|Unknown)s/%(title)s [%(id)s].%(ext)s' \
            "$playlist"
        done
      '';
    };

    systemd.timers.yt-playlist-sync = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "03:00";
        Persistent = true;
      };
    };
  };
}
