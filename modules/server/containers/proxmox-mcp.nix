{ lab, ... }:

{
  virtualisation.oci-containers.containers.proxmox-mcp = lab.mkContainer {
    image = "ghcr.io/ry-ops/proxmox-mcp-server:latest";
    cmd = [ "proxmox-mcp-server-http" ];
    environmentFiles = [ "${lab.secrets}/proxmox-mcp.env" ];
    environment = {
      MCP_HTTP_HOST = "0.0.0.0";
      MCP_HTTP_PORT = "8811";
      PROXMOX_READ_ONLY = "true";
    };
    traefik = {
      name = "proxmox-mcp";
      port = 8811;
    };
  };
}
