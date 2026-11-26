{ lab, pkgs, ... }:

# T3 Code server with Google's Antigravity agent, isolated from the desktop T3.
# T3 installs and signs in its own Antigravity runtime and downloads its own
# headless Chromium; the apt Chromium supplies that browser's libraries and fonts.
let
  dockerfile = pkgs.writeText "t3code.Dockerfile" ''
    FROM node:24-trixie-slim
    RUN apt-get update \
      && apt-get install -y --no-install-recommends \
        ca-certificates curl git openssh-client ripgrep chromium fonts-liberation fonts-noto-color-emoji \
      && rm -rf /var/lib/apt/lists/*
    RUN npm install --global t3@latest && npm cache clean --force
  '';

  localImage = lab.mkImage {
    name = "t3code";
    inherit dockerfile;
  };

  # The image's node user.
  uid = "1000";
  state = "${lab.appdata}/t3code";
in
{
  systemd.tmpfiles.rules = [
    "d ${state} 0700 ${uid} ${uid} -"
    "d ${state}/home 0700 ${uid} ${uid} -"
    "d ${state}/workspace 0755 ${uid} ${uid} -"
  ];

  systemd.services.docker-image-t3code = localImage.service;

  virtualisation.oci-containers.containers.t3code = lab.mkContainer {
    inherit (localImage) image;
    pull = "never";
    user = uid;
    workdir = "/workspace";
    cmd = [
      "t3"
      "serve"
      "--host"
      "0.0.0.0"
      "--port"
      "3773"
      "--no-browser"
      "/workspace"
    ];
    volumes = [
      "${state}/home:/home/node:rw"
      "${state}/workspace:/workspace:rw"
    ];
    environment = {
      HOME = "/home/node";
      # Docker's seccomp profile denies the user namespaces Chrome's sandbox needs;
      # the container stands in for it.
      T3CODE_SERVER_BROWSER_SANDBOX = "0";
    };
    capabilities.ALL = false;
    extraOptions = [
      "--security-opt=no-new-privileges"
      "--pids-limit=2048"
      "--shm-size=1g"
      "--memory=4g"
      "--cpus=2"
    ];
    traefik = {
      name = "t3code";
      port = 3773;
    };
  };
}
