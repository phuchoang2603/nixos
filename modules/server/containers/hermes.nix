{
  lab,
  lib,
  pkgs,
  ...
}:

let
  upstreamImage = "nousresearch/hermes-agent:latest";
  image = "hermes-agent-local:latest";
  # The upstream image lacks libopus (Discord voice playback) and hindsight-client (the Hindsight
  # memory plugin); the container is recreated on every start, so runtime installs don't stick.
  # browser_exec on a configured cdp_url can't reach a CDP endpoint inside the sandbox without the
  # exec-stream forward, and has to bring the screen up first.
  # The grep fails the build, keeping the previous image, once upstream moves the patched code.
  dockerfile = pkgs.writeText "hermes-agent-local.Dockerfile" ''
    FROM ${upstreamImage}
    COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv
    RUN apt-get update \
      && apt-get install -y --no-install-recommends libopus0 \
      && rm -rf /var/lib/apt/lists/*
    RUN uv pip install --no-cache --python /opt/hermes/.venv/bin/python 'hindsight-client>=0.10.1,<1' \
      && /opt/hermes/.venv/bin/python -c 'import hindsight_client'
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
  ];
  pluginList = builtins.toJSON plugins;

  # Memory provider from Hermes' plugin catalog, at the commit the catalog pins.
  # Hermes marks cron and subagent agents so providers skip writes, but this release still
  # retains them; the patch keeps scheduled-job transcripts out of memory.
  hindsightPlugin =
    pkgs.runCommand "hermes-hindsight-plugin"
      {
        src = pkgs.fetchFromGitHub {
          owner = "vectorize-io";
          repo = "hindsight";
          rev = "d56c4acdf59c41957613d399094cdf8c489b060c";
          sparseCheckout = [ "hindsight-integrations/hermes" ];
          hash = "sha256-8QxHgplP1FjlwRzynj+sr9mmQjATkJBLiW9BtDawNPY=";
        };
      }
      ''
        cp -r $src/hindsight-integrations/hermes $out
        chmod -R u+w $out
        substituteInPlace $out/__init__.py --replace-fail \
          'if not self._auto_retain' \
          'if not self._auto_retain or self._platform in ("cron", "subagent")'
      '';

  hindsightConfig = pkgs.writeText "hindsight-config.json" (
    builtins.toJSON {
      mode = "local_external";
      api_url = "http://hindsight:8888";
      bank_id = "hermes";
      memory_mode = "hybrid";
      recall_budget = "mid";
      # The default injects the previous message's recall; sync matches the current one.
      recall_sync = true;
      recall_max_tokens = 2048;
      # By default recall first waits up to 10s for the previous turn's retain to finish
      # extraction, which alone overruns Hermes' 8s prefetch timeout. That turn is still in
      # the conversation context, so recall doesn't need it.
      prefetch_waits_for_retain = false;
      retain_context = "Discord conversation between Felix and Hermes, his personal agent";
      retain_source = "hermes";
      retain_user_prefix = "Felix";
      retain_assistant_prefix = "Hermes";
      # Retains are tagged with their session id, and observations are scoped to a memory's
      # tags by default, which would keep each session's observations apart.
      observation_scopes = "shared";
    }
  );

  managedConfig = (pkgs.formats.yaml { }).generate "hermes-config.yaml" {
    model = {
      provider = "custom";
      base_url = "http://cli-proxy-api:8317/v1";
      api_key = "cliproxyapi";
      default = "gemini-3.8-flash-high";
    };
    mcp_servers.executor.url = "https://${lab.fqdn "mcp"}/mcp?mode=passthrough";
    # Hindsight holds long-term memory. With MEMORY.md also on, the model favours the built-in
    # store; USER.md stays as the always-injected profile.
    memory = {
      provider = "hindsight";
      memory_enabled = false;
    };
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
  systemd.services.docker-hermes.after = [
    "docker-hermes-desktop.service"
    "docker-hindsight.service"
  ];
  systemd.services.docker-hermes.wants = [
    "docker-hermes-desktop.service"
    "docker-hindsight.service"
  ];

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

    install -d -o ${uid} -g ${gid} -m 0700 ${state}/hindsight
    install -o ${uid} -g ${gid} -m 0600 ${hindsightConfig} ${state}/hindsight/config.json

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
    ++ [ "${hindsightPlugin}:/opt/data/plugins/hindsight:ro" ]
    ++ map (dir: "${shared}/${dir}:/opt/data/${dir}:rw") sharedDirs;
    environmentFiles = [ "${lab.secrets}/hermes.env" ];
    environment = {
      PUID = uid;
      PGID = gid;
      HERMES_DASHBOARD = "1";
      DISCORD_HOME_CHANNEL = discordChannels.reports;
      REALTIME_VOICE_LOG_CHANNEL = discordChannels.main;
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
