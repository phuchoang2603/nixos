{ lab, ... }:

# OmniRoute: OpenAI-compatible gateway. Dashboard + /v1 on :20128 (Traefik).
# Redis is docker-network only.
let
  data = "${lab.appdata}/omniroute";
  envFile = "${lab.secrets}/omniroute.env";
  # OmniRoute runs as uid 1000; DATA_DIR must be writable for sqlite/server.env.
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
      extraOptions = [
        "--memory=256m"
        "--security-opt=no-new-privileges"
      ];
    };

    omniroute = lab.mkContainer {
      # latest-web = base + Playwright/Chromium for gemini-web / claude-web.
      image = "docker.io/diegosouzapw/omniroute:latest-web";
      dependsOn = [ "omniroute-redis" ];
      volumes = [ "${data}/data:/app/data:rw" ];
      environmentFiles = [ envFile ];
      environment = {
        DATA_DIR = "/app/data";
        REDIS_URL = "redis://omniroute-redis:6379";
        DASHBOARD_PORT = "20128";
        API_PORT = "20129";
        LIVE_WS_PORT = "20132";
        API_HOST = "0.0.0.0";
        REQUIRE_API_KEY = "false";
        # ChatGPT Codex omits gpt-6.1-* below ~0.159 (OmniRoute#16714).
        CODEX_CLIENT_VERSION = "0.163.0";
        NEXT_PUBLIC_BASE_URL = "https://${lab.fqdn "omniroute"}";
        BASE_URL = "http://omniroute:20128";
        OMNIROUTE_MEMORY_MB = "4096";
        NODE_ENV = "production";
        INSTANCE_NAME = "omniroute";
      };
      extraOptions = [
        "--stop-timeout=40"
        # Chromium needs shared memory; Playwright defaults fail with tiny /dev/shm.
        "--shm-size=2g"
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
