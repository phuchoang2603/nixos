{ lib, pkgs, ... }:

let
  proxmoxMcp = pkgs.writeShellApplication {
    name = "proxmox-mcp";
    runtimeInputs = [ pkgs.docker ];
    text = ''
      exec docker run -i --rm \
        --env-file /run/agenix/proxmox-mcp.env \
        -e PROXMOX_READ_ONLY=true \
        ghcr.io/ry-ops/proxmox-mcp-server:latest
    '';
  };
in
{
  imports = [ ../base/cli.nix ];

  programs.mcp.servers.proxmox.command = lib.getExe proxmoxMcp;
}
