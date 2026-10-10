{
  lab,
  lib,
  pkgs,
  ...
}:

let
  image = "nousresearch/hermes-agent:latest";
  # Hermes runs as this user so the NFS-backed files stay editable from the desktop.
  uid = "1000";
  gid = "100";

  # SQLite state (state.db, sessions) must stay off NFS.
  state = "/var/lib/hermes";

  discordChannels = {
    main = "1558532054889660416";
    tasks = "1558532205507125299";
    reports = "1558532114423484507";
  };
  # Agent-evolved files: its own skills, memories, cron jobs, persona.
  shared = "${lab.appdata}/hermes";
  sharedDirs = [
    "skills"
    "memories"
    "cron"
    "soul"
  ];

  managedConfig = (pkgs.formats.yaml { }).generate "hermes-config.yaml" {
    model = {
      provider = "custom";
      base_url = "http://cli-proxy-api:8317/v1";
      api_key = "cliproxyapi";
      default = "gemini-3.8-flash-high";
    };
    mcp_servers.executor.url = "https://${lab.fqdn "mcp"}/mcp?mode=passthrough";
    discord = {
      free_response_channels = with discordChannels; [
        main
        tasks
      ];
      free_response_auto_thread = true;
      missed_message_backfill.enabled = true;
    };
    dashboard = {
      public_url = "https://${lab.fqdn "hermes"}";
      trusted_proxies = [ "172.18.0.0/16" ];
    };
  };
in
{
  systemd.tmpfiles.rules = [
    "d ${state} 0700 ${uid} ${gid} -"
    "d ${shared} 0755 ${uid} ${gid} -"
  ]
  ++ map (dir: "d ${shared}/${dir} 0755 ${uid} ${gid} -") sharedDirs;

  # Hermes rewrites config.yaml itself (migrations, /model, "always allow"),
  # so the Nix-owned keys are merged in on each start instead of mounted read-only.
  systemd.services.docker-hermes.preStart = lib.mkBefore ''
    cfg=${state}/config.yaml
    if [ -f "$cfg" ]; then
      ${lib.getExe pkgs.yq-go} ea '. as $i ireduce ({}; . * $i)' "$cfg" ${managedConfig} > "$cfg.tmp"
      mv "$cfg.tmp" "$cfg"
    else
      install -m 0600 ${managedConfig} "$cfg"
    fi
    chown ${uid}:${gid} "$cfg"

    if [ ! -e ${shared}/soul/SOUL.md ]; then
      install -o ${uid} -g ${gid} -m 0644 ${./hermes/SOUL.md} ${shared}/soul/SOUL.md
    fi
    # Hermes only reads SOUL.md from the root of its home; its file tool resolves symlinks before writing.
    ln -sfn soul/SOUL.md ${state}/SOUL.md
  '';

  virtualisation.oci-containers.containers.hermes = lab.mkContainer {
    inherit image;
    cmd = [
      "gateway"
      "run"
    ];
    volumes = [
      "${state}:/opt/data:rw"
    ]
    ++ map (dir: "${shared}/${dir}:/opt/data/${dir}:rw") sharedDirs;
    environmentFiles = [ "${lab.secrets}/hermes.env" ];
    environment = {
      PUID = uid;
      PGID = gid;
      HERMES_DASHBOARD = "1";
      DISCORD_HOME_CHANNEL = discordChannels.reports;
    };
    extraOptions = [
      "--shm-size=1g"
      "--memory=4g"
      "--cpus=2"
      "--security-opt=no-new-privileges"
    ];
    traefik = {
      name = "hermes";
      port = 9119;
    };
  };
}
