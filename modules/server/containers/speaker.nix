{
  lab,
  lib,
  pkgs,
  ...
}:

# Hermes' speaker: music and speech on the speaker in pve's front headphone jack.
# The "audio" LXC on pve (CT 120, 10.69.1.110) owns the sound card and runs PipeWire, taking
# PulseAudio-protocol audio from this VM only. This container decides what plays and serves the
# tools to Executor at http://speaker:8000/mcp; it has no Traefik route. Music streams from
# Jellyfin; speaker.env holds JELLYFIN_API_KEY.
let
  image = "speaker:latest";
  voice = "en_US-lessac-medium";
  voiceBase = "https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/lessac/medium";
  dockerfile = pkgs.writeText "speaker.Dockerfile" ''
    FROM python:3.13-slim
    RUN apt-get update \
      && apt-get install -y --no-install-recommends mpv ca-certificates \
      && rm -rf /var/lib/apt/lists/*
    RUN pip install --no-cache-dir "mcp>=2,<3" httpx piper-tts \
      && mkdir /voices \
      && for f in ${voice}.onnx ${voice}.onnx.json; do \
           python -c 'import sys, urllib.request; urllib.request.urlretrieve(*sys.argv[1:])' ${voiceBase}/$f /voices/$f; \
         done
  '';
in
{
  systemd.services.docker-speaker.preStart = lib.mkBefore ''
    ${pkgs.docker}/bin/docker build --pull -t ${image} - < ${dockerfile} \
      || ${pkgs.docker}/bin/docker image inspect ${image} > /dev/null
  '';

  virtualisation.oci-containers.containers.speaker = lab.mkContainer {
    inherit image;
    pull = "never";
    user = "1000:1000";
    cmd = [
      "python"
      "/app/server.py"
    ];
    volumes = [ "${./speaker/server.py}:/app/server.py:ro" ];
    environment = {
      HOME = "/tmp";
      PULSE_SERVER = "tcp:10.69.1.110:4713";
      PIPER_VOICE = "/voices/${voice}.onnx";
      JELLYFIN_URL = "http://jellyfin:8096";
    };
    environmentFiles = [ "${lab.secrets}/speaker.env" ];
    extraOptions = [
      "--cap-drop=ALL"
      "--security-opt=no-new-privileges"
      "--read-only"
      "--tmpfs=/tmp:rw,nosuid,size=256m"
      "--memory=1g"
      "--cpus=1"
    ];
  };
}
