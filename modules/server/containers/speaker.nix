{
  lab,
  lib,
  pkgs,
  ...
}:

# Hermes' speaker, in pve's front headphone jack. The "audio" LXC on pve (CT 120, 10.69.1.110)
# owns the sound card and runs PipeWire, taking PulseAudio-protocol audio from this VM only.
#
# speaker-player is Jellyfin MPV Shim, a Jellyfin client logged in as Felix and shown in Jellyfin
# as the "Speaker" device: anything that can cast in Jellyfin can play on it, and its plays count
# in Jellyfin. speaker serves Hermes' tools to Executor at http://speaker:8000/mcp (no Traefik
# route): AudioMuse-AI (http://audiomuse:8000) picks the songs, the player is driven through
# Jellyfin's remote-control API, and speech comes from Piper.
# speaker.env holds JELLYFIN_API_KEY.
#
# The player logs in once with Quick Connect: on its first start it prints a code in its log, to
# approve in Jellyfin (user menu -> Quick Connect).
let
  player = "Speaker";
  pulse = "tcp:10.69.1.110:4713";
  playerState = "/var/lib/speaker-player";
  voice = "en_US-lessac-medium";
  voiceBase = "https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/lessac/medium";

  playerConf = pkgs.writeText "speaker-player-conf.json" (
    builtins.toJSON {
      enable_gui = false;
      player_name = player;
      music_volume = 60;
      check_updates = false;
      notify_updates = "disabled";
    }
  );
  # There is no screen: album art would otherwise be shown as video.
  playerMpvConf = pkgs.writeText "speaker-player-mpv.conf" ''
    vo=null
    audio-display=no
    force-window=no
  '';

  images = {
    # The release feed changes with each shim release, so a restart rebuilds with the newest.
    speaker-player = pkgs.writeText "speaker-player.Dockerfile" ''
      FROM python:3.13-slim
      RUN apt-get update \
        && apt-get install -y --no-install-recommends libmpv2 ca-certificates \
        && rm -rf /var/lib/apt/lists/*
      ADD https://pypi.org/rss/project/jellyfin-mpv-shim/releases.xml /tmp/releases.xml
      RUN pip install --no-cache-dir jellyfin-mpv-shim && rm /tmp/releases.xml
    '';
    speaker = pkgs.writeText "speaker.Dockerfile" ''
      FROM python:3.13-slim
      RUN apt-get update \
        && apt-get install -y --no-install-recommends pulseaudio-utils ca-certificates \
        && rm -rf /var/lib/apt/lists/*
      RUN pip install --no-cache-dir "mcp>=2,<3" httpx piper-tts \
        && mkdir /voices \
        && for f in ${voice}.onnx ${voice}.onnx.json; do \
             python -c 'import sys, urllib.request; urllib.request.urlretrieve(*sys.argv[1:])' ${voiceBase}/$f /voices/$f; \
           done
    '';
  };

  build = name: ''
    ${pkgs.docker}/bin/docker build --pull -t ${name}:latest - < ${images.${name}} \
      || ${pkgs.docker}/bin/docker image inspect ${name}:latest > /dev/null
  '';
  hardening = [
    "--cap-drop=ALL"
    "--security-opt=no-new-privileges"
    "--read-only"
    "--tmpfs=/tmp:rw,nosuid,size=256m"
    "--memory=1g"
    "--cpus=1"
  ];
in
{
  systemd.tmpfiles.rules = [
    "d ${playerState} 0700 1000 100 -"
    "C ${playerState}/conf.json 0600 1000 100 - ${playerConf}"
    "C ${playerState}/mpv.conf 0644 1000 100 - ${playerMpvConf}"
  ];

  systemd.services.docker-speaker-player.preStart = lib.mkBefore (build "speaker-player");
  systemd.services.docker-speaker.preStart = lib.mkBefore (build "speaker");

  virtualisation.oci-containers.containers = {
    speaker-player = lab.mkContainer {
      image = "speaker-player:latest";
      pull = "never";
      user = "1000:100";
      cmd = [
        "jellyfin-mpv-shim"
        "--config"
        "/config"
        "--no-gui"
        "--quick-connect"
        "--server"
        "http://jellyfin:8096"
      ];
      volumes = [ "${playerState}:/config:rw" ];
      environment = {
        HOME = "/tmp";
        USER = "speaker";
        PULSE_SERVER = pulse;
      };
      extraOptions = hardening;
    };

    speaker = lab.mkContainer {
      image = "speaker:latest";
      pull = "never";
      user = "1000:100";
      cmd = [
        "python"
        "/app/server.py"
      ];
      volumes = [ "${./speaker/server.py}:/app/server.py:ro" ];
      environment = {
        HOME = "/tmp";
        PULSE_SERVER = pulse;
        PIPER_VOICE = "/voices/${voice}.onnx";
        JELLYFIN_URL = "http://jellyfin:8096";
        AUDIOMUSE_URL = "http://audiomuse:8000";
        SPEAKER_PLAYER = player;
      };
      environmentFiles = [ "${lab.secrets}/speaker.env" ];
      extraOptions = hardening;
    };
  };
}
