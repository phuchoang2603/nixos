{
  lab,
  lib,
  pkgs,
  ...
}:

let
  upstreamImage = "nousresearch/hermes-agent:latest";
  image = "hermes-agent-local:latest";
  # The upstream image lacks libopus (Discord voice playback) and the bw CLI (Vaultwarden logins).
  # Vault autofill, and browser_exec on a configured cdp_url, can't reach a CDP endpoint inside the
  # sandbox without the exec-stream forward; the cdp_url path also has to bring the screen up.
  # The greps fail the build, keeping the previous image, once upstream moves the patched code.
  dockerfile = pkgs.writeText "hermes-agent-local.Dockerfile" ''
    FROM ${upstreamImage}
    RUN apt-get update \
      && apt-get install -y --no-install-recommends libopus0 \
      && rm -rf /var/lib/apt/lists/*
    RUN npm install -g --prefix /usr/local @bitwarden/cli \
      && npm cache clean --force
    RUN sed -i \
        -e 's/cdp_url=_resolve_cdp_override(cdp_url),/cdp_url=_resolve_cdp_override(_reach_sandbox_cdp(cdp_url)),/' \
        -e '/from tools.browser_tool_cdp import _get_dialog_policy_config, _resolve_cdp_override/a\    from tools.browser_use_cli import _reach_sandbox_cdp' \
        /opt/hermes/tools/browser_vault_tool.py \
      && grep -q '_resolve_cdp_override(_reach_sandbox_cdp(cdp_url))' /opt/hermes/tools/browser_vault_tool.py
    RUN sed -i \
        -e 's/^        _set_cdp_env(env, override)$/        from tools.bot_desktop import runtime as _bd_runtime\n        _bd_runtime.ensure_started_for_tool()\n        _set_cdp_env(env, _reach_sandbox_cdp(override))/' \
        /opt/hermes/tools/browser_use_cli.py \
      && grep -q '_set_cdp_env(env, _reach_sandbox_cdp(override))' /opt/hermes/tools/browser_use_cli.py
  '';

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

  # Local plugins under ./hermes/plugins, mounted read-only and enabled on start.
  plugins = [
    "model-autocomplete"
    "realtime-voice"
    "vault-autounlock"
  ];
  pluginList = builtins.toJSON plugins;

  managedConfig = (pkgs.formats.yaml { }).generate "hermes-config.yaml" {
    model = {
      provider = "custom";
      base_url = "http://cli-proxy-api:8317/v1";
      api_key = "cliproxyapi";
      default = "gemini-3.8-flash-high";
    };
    mcp_servers.executor.url = "https://${lab.fqdn "mcp"}/mcp?mode=passthrough";
    # Terminal, browser and computer_use run in the hermes-desktop sandbox.
    terminal = {
      backend = "ssh";
      ssh_host = "hermes-desktop";
      ssh_user = "pn";
      ssh_port = 2222;
      ssh_key = "/opt/data/.ssh/desktop_ed25519";
    };
    browser = {
      # Stock Chrome inside the sandbox (hermes-desktop's chrome-keeper), reached over the SSH session.
      cdp_url = "http://127.0.0.1:9222";
      # Keeps a page open while Felix answers a verification challenge from Discord.
      inactivity_timeout = 1800;
    };
    # Voice runs through the realtime-voice plugin, not Hermes' chained STT/TTS.
    stt.enabled = false;
    agent.disabled_toolsets = [ "tts" ];
    discord = {
      free_response_channels = with discordChannels; [
        main
        tasks
      ];
      free_response_auto_thread = true;
      missed_message_backfill.enabled = true;
      gateway_restart_notification = false;
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

  # hermes-desktop's preStart creates the SSH key Hermes logs in with.
  systemd.services.docker-hermes.after = [ "docker-hermes-desktop.service" ];
  systemd.services.docker-hermes.wants = [ "docker-hermes-desktop.service" ];

  # Hermes rewrites config.yaml itself (migrations, /model, "always allow"),
  # so the Nix-owned keys are merged in on each start instead of mounted read-only.
  systemd.services.docker-hermes.preStart = lib.mkBefore ''
    ${pkgs.docker}/bin/docker build --pull -t ${image} - < ${dockerfile} \
      || ${pkgs.docker}/bin/docker image inspect ${image} > /dev/null

    cfg=${state}/config.yaml
    if [ -f "$cfg" ]; then
      ${lib.getExe pkgs.yq-go} ea '. as $i ireduce ({}; . * $i)' "$cfg" ${managedConfig} > "$cfg.tmp"
      mv "$cfg.tmp" "$cfg"
    else
      install -m 0600 ${managedConfig} "$cfg"
    fi
    ${lib.getExe pkgs.yq-go} -i '.plugins.enabled = ((.plugins.enabled // []) + ${pluginList} | unique)' "$cfg"
    chown ${uid}:${gid} "$cfg"

    if [ ! -e ${shared}/soul/SOUL.md ]; then
      install -o ${uid} -g ${gid} -m 0644 ${./hermes/SOUL.md} ${shared}/soul/SOUL.md
    fi
    # Hermes only reads SOUL.md from the root of its home; its file tool resolves symlinks before writing.
    ln -sfn soul/SOUL.md ${state}/SOUL.md
  '';

  virtualisation.oci-containers.containers.hermes = lab.mkContainer {
    inherit image;
    pull = "never";
    cmd = [
      "gateway"
      "run"
    ];
    volumes = [
      "${state}:/opt/data:rw"
    ]
    ++ map (name: "${./hermes/plugins/${name}}:/opt/data/plugins/${name}:ro") plugins
    ++ map (dir: "${shared}/${dir}:/opt/data/${dir}:rw") sharedDirs;
    environmentFiles = [ "${lab.secrets}/hermes.env" ];
    environment = {
      PUID = uid;
      PGID = gid;
      HERMES_DASHBOARD = "1";
      DISCORD_HOME_CHANNEL = discordChannels.reports;
      REALTIME_VOICE_LOG_CHANNEL = discordChannels.main;
      BITWARDENCLI_APPDATA_DIR = "/opt/data/bitwarden";
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
