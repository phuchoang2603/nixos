{ pkgs, ... }:

let
  sharedContext = ./AGENTS.md;
  agentSkills = ./skills;
  gatewayDomain = (import ../../../../modules/server/lib.nix).domain;
in
{
  imports = [
    ./claude.nix
    ./codex.nix
    ./t3code.nix
  ];

  home.packages = [
    (pkgs.writers.writePython3Bin "excalidraw-icon" { flakeIgnore = [ "E501" ]; } (
      builtins.readFile ./scripts/excalidraw-icon.py
    ))
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
  programs.claude-code.skills = agentSkills;

  # Shared Context
  programs.codex.context = sharedContext;
  programs.claude-code.context = sharedContext;
}
