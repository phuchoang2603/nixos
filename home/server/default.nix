{ lib, pkgs, ... }:

let
  proxmoxMcp = pkgs.writeShellApplication {
    name = "proxmox-mcp";
    runtimeInputs = [ pkgs.docker ];
    text = ''
      exec docker run -i --rm \
        --add-host pve.lan:10.69.1.1 \
        --env-file /run/agenix/proxmox-mcp.env \
        -e PROXMOX_HOST=pve.lan \
        -e PROXMOX_VERIFY_SSL=true \
        -e PROXMOX_CA_BUNDLE=/pve-root-ca.pem \
        -e PROXMOX_READ_ONLY=true \
        -v ${./pve-root-ca.pem}:/pve-root-ca.pem:ro \
        ghcr.io/ry-ops/proxmox-mcp-server:latest
    '';
  };
in
{
  imports = [ ../base/cli.nix ];

  programs.mcp.servers.proxmox.command = lib.getExe proxmoxMcp;
}
