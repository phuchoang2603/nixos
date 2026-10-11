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
  image = "hermes-desktop:latest";
  dockerfile = pkgs.writeText "hermes-desktop.Dockerfile" ''
    FROM ${upstreamImage}
    RUN apt-get update \
      && apt-get install -y --no-install-recommends openssh-server \
      && rm -rf /var/lib/apt/lists/*
  '';

  # The image's desktop user; Hermes logs in as it and runs Xvnc/Chromium as it.
  user = "pn";
  uid = "1000";
  state = "/var/lib/hermes-desktop";
  hermesState = "/var/lib/hermes";
  hermesOwner = "1000:100";
  hermesKey = "${hermesState}/.ssh/desktop_ed25519";

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
  ];

  systemd.services.docker-hermes-desktop.preStart = lib.mkBefore ''
    ${pkgs.docker}/bin/docker build --pull -t ${image} - < ${dockerfile} \
      || ${pkgs.docker}/bin/docker image inspect ${image} > /dev/null

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
    if [ -d $home/.hermes/bot-desktop ] && [ ! -L $home/.hermes/bot-desktop ]; then
      cp -a $home/.hermes/bot-desktop/. $home/.bot-desktop/
      rm -rf $home/.hermes/bot-desktop
    fi
    ln -sfn ../.bot-desktop $home/.hermes/bot-desktop
    chown -h ${uid}:${uid} $home/.hermes/bot-desktop
  '';

  virtualisation.oci-containers.containers.hermes-desktop = lab.mkContainer {
    inherit image user;
    pull = "never";
    entrypoint = "/usr/sbin/sshd";
    cmd = [
      "-D"
      "-e"
    ];
    volumes = [
      "${state}/home:/home/${user}:rw"
      "${state}/ssh:/etc/hermes-desktop:ro"
      "${sshdConfig}:/etc/ssh/sshd_config:ro"
    ];
    extraOptions = [
      "--cap-drop=ALL"
      "--security-opt=no-new-privileges"
      "--pids-limit=2048"
      "--tmpfs=/tmp:rw,nosuid,size=1g"
      "--shm-size=1g"
      "--memory=3g"
      "--cpus=2"
    ];
  };
}
