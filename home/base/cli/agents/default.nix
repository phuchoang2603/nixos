{
  pkgs,
  ...
}:

let
  sharedContext = ./AGENTS.md;
  agentSkills = ./skills;
in
{
  imports = [
    ./cursor.nix
    ./codex.nix
    ./t3code.nix
  ];

  home.packages = with pkgs; [
    pi-coding-agent
    openspec
  ];

  # Shared MCP Servers
  programs.mcp = {
    enable = true;
    servers = {
      context7 = {
        url = "https://mcp.context7.com/mcp";
      };
    };
  };

  # Shared Skills
  programs.codex.skills = agentSkills;
  programs.cursor-agent.skillsDir = agentSkills;

  # Shared Context
  programs.codex.context = sharedContext;
  programs.cursor-agent.rules.global-context = sharedContext;
}
