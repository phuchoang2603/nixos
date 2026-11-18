{ pkgs, ... }:

let
  gatewayDomain = (import ../../../../modules/server/lib.nix).domain;
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
    };
  };
}
