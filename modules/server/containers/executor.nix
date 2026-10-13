{ lab, pkgs, ... }:

let
  data = "/var/lib/executor";
  # The image runs as distroless `nonroot`.
  uid = "65532";

  # Stdio MCP servers are baked in because `bun x` cannot run package bins in
  # the distroless image. Register them in Executor as stdio
  # integrations with command `bun` and args
  # `/mcp/node_modules/<package>/<bin>`.
  stdioServers = pkgs.writeText "executor-mcp-package.json" (
    builtins.toJSON {
      private = true;
      dependencies = {
        "mcp-excalidraw-server" = "2.1.2";
        "@karakeep/mcp" = "0.33.1";
        "@bldg-7/proxmox-mcp" = "1.3.0";
      };
    }
  );

  localImage = lab.mkImage {
    name = "executor";
    context = pkgs.runCommand "executor-mcp-context" { } ''
      mkdir "$out"
      cp ${stdioServers} "$out/package.json"
    '';
    dockerfile = pkgs.writeText "executor.Dockerfile" ''
      FROM ghcr.io/rhyssullivan/executor-selfhost:latest
      USER 0
      COPY package.json /mcp/package.json
      RUN ["bun", "install", "--cwd", "/mcp", "--production"]
      USER ${uid}:${uid}
    '';
  };
in
{
  systemd.tmpfiles.rules = [
    "d ${data} 0700 ${uid} ${uid} -"
    "d ${data}/data 0700 ${uid} ${uid} -"
  ];

  systemd.services.docker-image-executor = localImage.service;

  virtualisation.oci-containers.containers.executor = lab.mkContainer {
    inherit (localImage) image;
    pull = "never";
    volumes = [ "${data}/data:/data:rw" ];
    environment = {
      EXECUTOR_WEB_BASE_URL = "https://${lab.fqdn "mcp"}";
      EXECUTOR_ALLOW_STDIO_MCP = "true";
      # Upstreams on the proxy network resolve to private addresses.
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
