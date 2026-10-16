{ lab, ... }:

# OmniRoute: OpenAI-compatible gateway with free-tier routing and token compression.
# Dashboard + /v1 on :20128 (Traefik). Redis is docker-network only.
let
  data = "${lab.appdata}/omniroute";
  envFile = "${lab.secrets}/omniroute.env";
in
{
  systemd.tmpfiles.rules = [
    "d ${data} 0755 root root -"
    "d ${data}/data 0755 root root -"
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
        DASHBOARD_PORT = "20128";
        API_PORT = "20129";
        LIVE_WS_PORT = "20132";
        # Listen on all interfaces inside the container so Traefik on the proxy
        # network can reach it. Do not publish these ports on the host.
        API_HOST = "0.0.0.0";
        # false keeps Codex/Hermes/Karakeep/Hindsight working with placeholder
        # keys on day one. Set true in omniroute.env after creating real API
        # keys in the dashboard (required before treating the URL as public).
        REQUIRE_API_KEY = "false";
        OMNIROUTE_MEMORY_MB = "2048";
        NEXT_PUBLIC_BASE_URL = "https://${lab.fqdn "omniroute"}";
        BASE_URL = "http://omniroute:20128";
        NODE_ENV = "production";
        INSTANCE_NAME = "omniroute";
      };
      extraOptions = [
        "--stop-timeout=40"
        "--memory=3g"
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
