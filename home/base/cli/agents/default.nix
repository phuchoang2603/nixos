{ lib, pkgs, ... }:

let
  sharedContext = ./AGENTS.md;
  agentSkills = ./skills;
  executorCli = pkgs.callPackage ./executor-cli.nix { };
in
{
  imports = [
    ./claude.nix
    ./codex.nix
    ./t3code.nix
  ];

  home.packages = [
    executorCli
  ]
  ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [
    # The apply workflow's resume tailoring compiles LaTeX and validates the PDF.
    pkgs.tectonic
    (pkgs.python3.withPackages (python: [ python.pypdf ]))
  ]
  ++ [
    (pkgs.writers.writePython3Bin "excalidraw-icon" { flakeIgnore = [ "E501" ]; } (
      builtins.readFile ./scripts/excalidraw-icon.py
    ))
  ];

  # Shared MCP Servers
  programs.mcp = {
    enable = true;
    servers = {
      executor = {
        command = lib.getExe executorCli;
        args = [ "mcp" ];
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
