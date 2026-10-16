{ pkgs, ... }:

let
  sharedContext = ./AGENTS.md;
  agentSkills = ./skills;
  gatewayDomain = (import ../../../../modules/server/lib.nix).domain;
in
{
  imports = [
    ./opencode.nix
    ./t3code.nix
    ./excalidraw.nix
  ];

  home.packages = with pkgs; [
    pi-coding-agent
    openspec
  ];
  # Shared MCP Servers
  programs.mcp = {
    enable = true;
    servers = {
      executor = {
        url = "https://mcp.${gatewayDomain}/mcp?mode=passthrough";
      };
    };
  };

  # Shared Skills
  programs.opencode.skills = agentSkills;

  # Shared Context
  programs.opencode.context = sharedContext;
}
