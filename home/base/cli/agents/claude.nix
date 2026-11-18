{ pkgs, ... }:

let
  gatewayDomain = (import ../../../../modules/server/lib.nix).domain;
  stopLint = pkgs.writeShellApplication {
    name = "agent-stop-lint";
    runtimeInputs = [
      pkgs.git
      pkgs.jq
    ];
    text = builtins.readFile ./scripts/stop-lint.sh;
  };
in
{
  programs.claude-code = {
    enable = true;
    package = pkgs.callPackage ./claude-cli.nix { };
    enableMcpIntegration = true;
    mutableSettings = true;
    settings = {
      model = "sonnet";
      env = {
        ANTHROPIC_BASE_URL = "https://cliproxyapi.${gatewayDomain}";
        ANTHROPIC_AUTH_TOKEN = "not-required";
      };
      hooks.Stop = [
        {
          hooks = [
            {
              type = "command";
              command = "${stopLint}/bin/agent-stop-lint";
              timeout = 600;
            }
          ];
        }
      ];
    };
  };
}
