{ ... }:

let
  gatewayDomain = (import ../../../../modules/server/lib.nix).domain;
in
{
  programs.claude-code = {
    enable = true;
    enableMcpIntegration = true;
    mutableSettings = true;
    settings = {
      model = "claude-sonnet-5.5";
      env = {
        ANTHROPIC_BASE_URL = "https://cliproxyapi.${gatewayDomain}";
        ANTHROPIC_AUTH_TOKEN = "not-required";
        ANTHROPIC_DEFAULT_SONNET_MODEL = "claude-sonnet-5.5";
        ANTHROPIC_DEFAULT_OPUS_MODEL = "claude-opus-5.5";
        ANTHROPIC_DEFAULT_HAIKU_MODEL = "claude-haiku-5.5";
        DISABLE_AUTOUPDATER = "1";
      };
    };
  };
}
