{ lab, pkgs, ... }:

let
  image = "ghcr.io/rhyssullivan/executor-selfhost:latest";
  data = "/var/lib/executor";
  # The image runs as distroless `nonroot`.
  uid = "65532";

  # Stdio MCP servers are installed ahead of time because `bun x` cannot run
  # package bins in the distroless image. Register them in Executor as stdio
  # integrations with command `bun` and args
  # `/mcp/node_modules/<package>/<bin>`.
  stdioServers = pkgs.writeText "executor-mcp-package.json" (
    builtins.toJSON {
      private = true;
      dependencies = {
        "mcp-excalidraw-server" = "2.1.2";
        "@karakeep/mcp" = "0.33.1";
      };
    }
  );
in
{
  systemd.tmpfiles.rules = [
    "d ${data} 0700 ${uid} ${uid} -"
    "d ${data}/data 0700 ${uid} ${uid} -"
    "d ${data}/mcp 0755 ${uid} ${uid} -"
  ];

  systemd.services.executor-mcp-install = {
    description = "Install stdio MCP servers for Executor";
    after = [
      "docker.service"
      "network-online.target"
    ];
    requires = [ "docker.service" ];
    wants = [ "network-online.target" ];
    before = [ "docker-executor.service" ];
    wantedBy = [ "docker-executor.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStartPre = "${pkgs.coreutils}/bin/install -o ${uid} -g ${uid} -m 0644 ${stdioServers} ${data}/mcp/package.json";
      ExecStart = "${pkgs.docker}/bin/docker run --rm -v ${data}/mcp:/mcp -w /mcp --entrypoint bun ${image} install --production";
    };
  };

  virtualisation.oci-containers.containers.executor = lab.mkContainer {
    inherit image;
    volumes = [
      "${data}/data:/data:rw"
      "${data}/mcp:/mcp:ro"
    ];
    environment = {
      EXECUTOR_WEB_BASE_URL = "https://${lab.fqdn "mcp"}";
      EXECUTOR_ALLOW_STDIO_MCP = "true";
      # Upstreams like obscura resolve to private addresses on the proxy network.
      EXECUTOR_ALLOW_LOCAL_NETWORK = "true";
    };
    traefik = {
      name = "mcp";
      port = 4788;
    };
    # Agents reach /mcp without credentials: Traefik injects EXECUTOR_API_KEY
    # from traefik.env. The web UI keeps its normal login.
    labels = {
      "traefik.http.routers.mcp-agents.rule" =
        "Host(`${lab.fqdn "mcp"}`) && (Path(`/mcp`) || PathPrefix(`/mcp/`))";
      "traefik.http.routers.mcp-agents.entrypoints" = "websecure";
      "traefik.http.routers.mcp-agents.tls" = "true";
      "traefik.http.routers.mcp-agents.tls.certresolver" = "letsencrypt";
      "traefik.http.routers.mcp-agents.service" = "mcp";
      "traefik.http.routers.mcp-agents.middlewares" = "executor-api-key@file";
    };
  };
}
