{
  config,
  lab,
  lib,
  pkgs,
  user,
  ...
}:

# Hindsight: Hermes' long-term memory (retain/recall/reflect over a knowledge graph).
# API on :8888 for Hermes, web UI on :9999 behind Traefik.
let
  state = "${lab.appdata}/hindsight";
  syncState = "${lab.appdata}/hindsight-obsidian";
  # Provision this file explicitly; keep the password when restoring the database.
  envFile = "${lab.secrets}/hindsight.env";

  vault = "${config.users.users.${user}.home}/repos/obsidian";
  # The CLI is a single bundled file; its one dependency is only loaded by --watch.
  obsidianSync = pkgs.fetchzip {
    url = "https://registry.npmjs.org/@vectorize-io/hindsight-obsidian/-/hindsight-obsidian-0.3.1.tgz";
    hash = "sha256-lvD/vdsC+kwyWZI6l3pZXdSTidoav04WaeeBKGAie0Y=";
  };
in
{
  systemd.tmpfiles.rules = [
    "d ${state} 0755 root root -"
    "d ${syncState} 0700 ${user} ${config.users.users.${user}.group} -"
  ];

  # Pulls the vault and syncs its notes into Hermes' bank (bank_id in hermes.nix), so recall
  # and the mental models see them. Only notes whose content changed are re-ingested. Deleted
  # notes are pruned by the index of what was sent, not by listing the bank, so the index must
  # persist and the sync never touches Hermes' own retains.
  systemd.services.hindsight-obsidian-sync = {
    description = "Sync the Obsidian vault into Hindsight";
    after = [
      "docker-hindsight.service"
      "network-online.target"
    ];
    wants = [ "network-online.target" ];
    requires = [ "docker-hindsight.service" ];
    unitConfig.RequiresMountsFor = [ syncState ];
    path = [
      pkgs.git
      pkgs.curl
    ];
    serviceConfig = {
      Type = "oneshot";
      User = user;
    };
    script = ''
      git -C ${vault} pull --ff-only || echo "git pull failed; syncing the vault as it is on disk" >&2
      curl -sf --retry 30 --retry-delay 10 --retry-all-errors http://127.0.0.1:8888/health > /dev/null
      ${lib.getExe pkgs.nodejs} ${obsidianSync}/dist/cli.js reconcile \
        --vault ${vault} \
        --bank hermes \
        --api-url http://127.0.0.1:8888 \
        --include journals --include people --include publish \
        --prefix-doc-id \
        --observation-scopes shared \
        --index ${syncState}/index.json
    '';
  };
  systemd.timers.hindsight-obsidian-sync = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "04:00";
      Persistent = true;
    };
  };

  systemd.services.docker-hindsight-db = lab.postgresReady "hindsight-db" "hindsight";

  virtualisation.oci-containers.containers = {
    hindsight-db = lab.mkContainer {
      image = "pgvector/pgvector:pg18";
      volumes = [ "${state}/postgres:/var/lib/postgresql/18/docker:rw" ];
      environmentFiles = [ envFile ];
      environment = {
        POSTGRES_USER = "hindsight";
        POSTGRES_DB = "hindsight";
      };
    };

    hindsight = lab.mkContainer {
      image = "ghcr.io/vectorize-io/hindsight:latest";
      dependsOn = [ "hindsight-db" ];
      # Loopback only, for the vault sync on the host.
      ports = [ "127.0.0.1:8888:8888" ];
      environmentFiles = [ envFile ];
      environment = {
        # Extraction, consolidation and reflect all go through the proxy; a flash-class model
        # keeps extraction quality up without the cost of the chat model.
        HINDSIGHT_API_LLM_PROVIDER = "openai";
        HINDSIGHT_API_LLM_BASE_URL = "http://omniroute:20128/v1";
        HINDSIGHT_API_LLM_API_KEY = "omniroute";
        HINDSIGHT_API_LLM_MODEL = "gpt-6-luna";
        # Caps background retain/consolidation so a burst of turns queues instead of
        # flooding the proxy accounts.
        HINDSIGHT_API_LLM_MAX_CONCURRENT = "4";
        HINDSIGHT_API_WORKER_MAX_SLOTS = "4";
        # Every turn is retained, so each message would otherwise rebuild every mental model
        # it touches; triggers inside the window fold into one queued refresh.
        HINDSIGHT_API_MENTAL_MODEL_MIN_REFRESH_INTERVAL_SECONDS = "1800";
        # Hermes drops a recall that takes over 8s. On this CPU the default cross-encoder
        # reranks 300 candidates in ~15s and FlashRank's default MiniLM-L-12 is slower still;
        # TinyBERT does it in ~2s with near-identical top results.
        HINDSIGHT_API_RERANKER_PROVIDER = "flashrank";
        HINDSIGHT_API_RERANKER_FLASHRANK_MODEL = "ms-marco-TinyBERT-L-2-v2";
        # Felix mixes Vietnamese and English; without this, facts and observations come out in
        # whatever language the model drifts to.
        HINDSIGHT_API_LLM_OUTPUT_LANGUAGE = "English";
      };
      extraOptions = [
        "--memory=3g"
        "--cpus=2"
        "--security-opt=no-new-privileges"
      ];
      traefik = {
        name = "hindsight";
        port = 9999;
      };
    };
  };
}
