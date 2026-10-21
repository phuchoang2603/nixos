{ ... }:

let
  sharedContext = ./AGENTS.md;
  agentSkills = ./skills;
  gatewayDomain = (import ../../../../modules/server/lib.nix).domain;
in
{
  imports = [
    ./codex.nix
    ./t3code.nix
    ./excalidraw.nix
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
  programs.codex.skills = agentSkills;

  # Shared Context
  programs.codex.context = sharedContext;
}
