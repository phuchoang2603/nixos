{ lab, ... }:

# OmniRoute: OpenAI-compatible gateway with free-tier routing and token compression.
# Dashboard + /v1 on :20128 (Traefik). Redis is docker-network only.
let
  data = "${lab.appdata}/omniroute";
  envFile = "${lab.secrets}/omniroute.env";
  publicOrigin = "https://${lab.fqdn "omniroute"}";
  # OmniRoute runs as uid/gid 1000 (node); sql.js persists to DATA_DIR.
  uid = "1000";
  gid = "1000";
in
{
  systemd.tmpfiles.rules = [
    "d ${data} 0755 ${uid} ${gid} -"
    "d ${data}/data 0755 ${uid} ${gid} -"
  ];

  virtualisation.oci-containers.containers = {
    omniroute-redis = lab.mkContainer {
      image = "docker.io/library/redis:8.6.5-alpine";
      # No host ports — only omniroute reaches this over the proxy network.
      extraOptions = [
        "--memory=256m"
        "--security-opt=no-new-privileges"
      ];
    };

    omniroute = lab.mkContainer {
      image = "docker.io/diegosouzapw/omniroute:latest";
      dependsOn = [ "omniroute-redis" ];
      volumes = [ "${data}/data:/app/data:rw" ];
      environmentFiles = [ envFile ];
      environment = {
        DATA_DIR = "/app/data";
        REDIS_URL = "redis://omniroute-redis:6379";
        PORT = "20128";
        DASHBOARD_PORT = "20128";
        API_PORT = "20129";
        LIVE_WS_PORT = "20132";
        # Traefik reaches the container on the proxy network; do not publish host ports.
        API_HOST = "0.0.0.0";
        LIVE_WS_HOST = "0.0.0.0";
        LIVE_WS_ALLOWED_ORIGINS = publicOrigin;

        # Public HTTPS via Traefik — required for session cookies.
        AUTH_COOKIE_SECURE = "true";
        ALLOW_API_KEY_REVEAL = "false";
        # Open /v1 for Codex and the other containers (no gateway API keys).
        REQUIRE_API_KEY = "false";

        # Prefer explicit public/internal URLs over trusting X-Forwarded-*.
        NEXT_PUBLIC_BASE_URL = publicOrigin;
        BASE_URL = "http://omniroute:20128";

        # Coding agents (/v1/responses) need a larger V8 heap than the image default (1024).
        OMNIROUTE_MEMORY_MB = "4096";
        # Long Codex/Claude streams; env.example recommends 10m for agent workloads.
        API_BRIDGE_PROXY_TIMEOUT_MS = "600000";
        API_BRIDGE_SERVER_REQUEST_TIMEOUT_MS = "600000";

        # Defaults worth pinning: warn-only injection scan, keep SQLite backups on.
        INPUT_SANITIZER_ENABLED = "true";
        INPUT_SANITIZER_MODE = "warn";
        DISABLE_SQLITE_AUTO_BACKUP = "false";

        NODE_ENV = "production";
        INSTANCE_NAME = "omniroute";
      };
      extraOptions = [
        "--stop-timeout=40"
        # Heap 4G + native buffers (SQLite, etc.).
        "--memory=5g"
        "--cpus=2"
        "--security-opt=no-new-privileges"
      ];
      traefik = {
        name = "omniroute";
        port = 20128;
      };
    };
  };
}
