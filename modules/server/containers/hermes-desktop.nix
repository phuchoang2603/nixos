{
  lab,
  lib,
  pkgs,
  ...
}:

# Hermes' sandbox: its terminal, browser and computer_use run here over SSH,
# away from the gateway's own state and secrets.
let
  upstreamImage = "nousresearch/hermes-sandbox:desktop";
  # Stock Chrome is downloaded when preparing a new image revision.
  dockerfile = pkgs.writeText "hermes-desktop.Dockerfile" ''
    FROM ${upstreamImage}
    ADD https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb /tmp/chrome.deb
    RUN apt-get update \
      && apt-get install -y --no-install-recommends openssh-server novnc python3-websockify /tmp/chrome.deb \
      && rm -rf /var/lib/apt/lists/* /tmp/chrome.deb
  '';

  localImage = lab.mkImage {
    name = "hermes-desktop";
    inherit dockerfile;
    containers = [
      "hermes-desktop"
      "hermes-desktop-vnc"
    ];
  };

  # Sites like Walmart block a Chrome that agent-browser launches (it reports navigator.webdriver),
  # so the browser tool attaches over CDP to stock Chrome started here instead. Docker's seccomp
  # profile denies the user namespaces Chrome's own sandbox needs; the container stands in for it.
  screenEnv = "/tmp/hermes-bot-desktop/default/env";
  cdpPort = 9222;
  chrome = pkgs.writeScript "chrome" ''
    #!/bin/sh
    if [ ! -f ${screenEnv} ]; then
      echo "Hermes' screen isn't running; take a computer_use capture to start it." >&2
      exit 1
    fi
    set -a
    . ${screenEnv}
    set +a
    setsid google-chrome-stable --no-sandbox --no-first-run --no-default-browser-check \
      --hide-crash-restore-bubble --password-store=basic --user-data-dir="$HOME/.chrome" \
      --remote-debugging-port=${toString cdpPort} "$@" > /dev/null 2>&1 &
  '';
  # Hermes starts and idles out the screen on its own; Chrome follows it.
  chromeKeeper = pkgs.writeScript "chrome-keeper" ''
    #!/bin/sh
    while sleep 2; do
      [ -f ${screenEnv} ] || continue
      DISPLAY=$(sed -n 's/^DISPLAY=//p' ${screenEnv}) XAUTHORITY=$(sed -n 's/^XAUTHORITY=//p' ${screenEnv}) \
        xdpyinfo > /dev/null 2>&1 || continue
      pgrep -f "user-data-dir=$HOME/.chrome" > /dev/null || chrome
    done
  '';

  # The image's desktop user; Hermes logs in as it and runs Xvnc/Chromium as it.
  user = "pn";
  uid = "1000";
  state = "${lab.appdata}/hermes-desktop";
  hermesState = "${lab.appdata}/hermes";
  hermesOwner = "1000:100";
  hermesKey = "${hermesState}/.ssh/desktop_ed25519";

  # Hermes' screen state (Xvnc's RFB socket included), shared with the noVNC viewer.
  screen = "/run/hermes-desktop";
  screenMount = "${screen}:/tmp/hermes-bot-desktop:rw";
  rfbSocket = "/tmp/hermes-bot-desktop/default/rfb.sock";

  # sshd runs unprivileged as the desktop user, so the container keeps no capabilities.
  sshdConfig = pkgs.writeText "hermes-desktop-sshd_config" ''
    Port 2222
    HostKey /etc/hermes-desktop/host_ed25519
    AuthorizedKeysFile /etc/hermes-desktop/authorized_keys
    PidFile none
    AllowUsers ${user}
    AuthenticationMethods publickey
    PasswordAuthentication no
    KbdInteractiveAuthentication no
    UsePAM no
    StrictModes no
    AllowTcpForwarding no
    AllowAgentForwarding no
    X11Forwarding no
    PermitTunnel no
    # SSH sessions don't inherit the image's ENV.
    SetEnv PLAYWRIGHT_BROWSERS_PATH=/opt/playwright XDG_RUNTIME_DIR=/tmp/hermes-runtime LANG=C.UTF-8
    Subsystem sftp internal-sftp
  '';
in
{
  systemd.tmpfiles.rules = [
    "d ${state} 0700 ${uid} ${uid} -"
    "d ${state}/home 0700 ${uid} ${uid} -"
    "d ${state}/ssh 0700 ${uid} ${uid} -"
    "d ${screen} 0700 ${uid} ${uid} -"
  ];

  systemd.services.docker-image-hermes-desktop = localImage.service;
  systemd.services.docker-hermes-desktop.preStart = lib.mkBefore ''
    keygen=${pkgs.openssh}/bin/ssh-keygen
    [ -f ${state}/ssh/host_ed25519 ] || $keygen -q -t ed25519 -N "" -C hermes-desktop -f ${state}/ssh/host_ed25519
    install -d -m 0700 ${hermesState}/.ssh
    [ -f ${hermesKey} ] || $keygen -q -t ed25519 -N "" -C hermes -f ${hermesKey}
    chown ${hermesOwner} ${hermesState}/.ssh ${hermesKey} ${hermesKey}.pub
    install -m 0600 ${hermesKey}.pub ${state}/ssh/authorized_keys
    chown -R ${uid}:${uid} ${state}/ssh

    # Hermes tars the remote ~/.hermes back after each session and rejects the absolute
    # symlinks Chromium keeps in its profile, so the desktop's state lives beside it.
    home=${state}/home
    install -d -o ${uid} -g ${uid} -m 0700 $home/.hermes $home/.bot-desktop
    ln -sfn ../.bot-desktop $home/.hermes/bot-desktop
    chown -h ${uid}:${uid} $home/.hermes/bot-desktop

    # A previous container's screen is dead; its pid files could match new processes.
    install -d -o ${uid} -g ${uid} -m 0700 ${screen}
    find ${screen} -mindepth 1 -delete
  '';

  virtualisation.oci-containers.containers.hermes-desktop = lab.mkContainer {
    inherit user;
    inherit (localImage) image;
    pull = "never";
    entrypoint = "/bin/sh";
    cmd = [
      "-c"
      "chrome-keeper & exec /usr/sbin/sshd -D -e"
    ];
    volumes = [
      "${state}/home:/home/${user}:rw"
      "${state}/ssh:/etc/hermes-desktop:ro"
      "${sshdConfig}:/etc/ssh/sshd_config:ro"
      "${chrome}:/usr/local/bin/chrome:ro"
      "${chromeKeeper}:/usr/local/bin/chrome-keeper:ro"
      screenMount
    ];
    capabilities.ALL = false;
    extraOptions = [
      "--security-opt=no-new-privileges"
      "--pids-limit=2048"
      "--tmpfs=/tmp:rw,nosuid,size=1g"
      "--shm-size=1g"
      "--memory=3g"
      "--cpus=2"
    ];
  };

  # Browser view of the desktop for solving challenges by hand, open to anyone on the LAN. It
  # bypasses Hermes' take-control lease, so the agent has to wait while Felix is on it.
  virtualisation.oci-containers.containers.hermes-desktop-vnc = lab.mkContainer {
    inherit user;
    inherit (localImage) image;
    pull = "never";
    dependsOn = [ "hermes-desktop" ];
    entrypoint = "websockify";
    cmd = [
      "--web=/usr/share/novnc"
      "--file-only"
      "--unix-target=${rfbSocket}"
      "6080"
    ];
    volumes = [ screenMount ];
    capabilities.ALL = false;
    extraOptions = [
      "--security-opt=no-new-privileges"
      "--read-only"
      "--memory=256m"
    ];
    traefik = {
      name = "desktop";
      port = 6080;
    };
    labels = {
      "traefik.http.routers.desktop.middlewares" = "desktop-viewer";
      "traefik.http.middlewares.desktop-viewer.redirectregex.regex" = "^https://([^/]+)/$";
      "traefik.http.middlewares.desktop-viewer.redirectregex.replacement" =
        "https://\${1}/vnc.html?autoconnect=true&resize=scale&reconnect=true";
    };
  };
}
