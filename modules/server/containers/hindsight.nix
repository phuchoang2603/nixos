{
  lab,
  lib,
  pkgs,
  ...
}:

# Hindsight: Hermes' long-term memory (retain/recall/reflect over a knowledge graph).
# API on :8888 for Hermes, web UI on :9999 behind Traefik.
let
  # Postgres must stay off NFS.
  state = "/var/lib/hindsight";
  # Generated on first start; holds only the database password.
  envFile = "${lab.secrets}/hindsight.env";
in
{
  systemd.tmpfiles.rules = [ "d ${state} 0755 root root -" ];

  systemd.services.docker-hindsight-db.preStart = lib.mkBefore ''
    if [ ! -s ${envFile} ]; then
      pw=$(${lib.getExe pkgs.openssl} rand -hex 24)
      (
        umask 077
        printf 'POSTGRES_PASSWORD=%s\nHINDSIGHT_API_DATABASE_URL=postgresql://hindsight:%s@hindsight-db:5432/hindsight\n' \
          "$pw" "$pw" > ${envFile}
      )
    fi
  '';

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
      environmentFiles = [ envFile ];
      environment = {
        # Extraction, consolidation and reflect all go through the proxy; a flash-class model
        # keeps extraction quality up without the cost of the chat model.
        HINDSIGHT_API_LLM_PROVIDER = "openai";
        HINDSIGHT_API_LLM_BASE_URL = "http://cli-proxy-api:8317/v1";
        HINDSIGHT_API_LLM_API_KEY = "cliproxyapi";
        HINDSIGHT_API_LLM_MODEL = "gpt-6-luna";
        # Caps background retain/consolidation so a burst of turns queues instead of
        # flooding the proxy accounts.
        HINDSIGHT_API_LLM_MAX_CONCURRENT = "4";
        HINDSIGHT_API_WORKER_MAX_SLOTS = "4";
        # Every turn is retained, so each message would otherwise rebuild every mental model
        # it touches; triggers inside the window fold into one queued refresh.
        HINDSIGHT_API_MENTAL_MODEL_MIN_REFRESH_INTERVAL_SECONDS = "1800";
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
