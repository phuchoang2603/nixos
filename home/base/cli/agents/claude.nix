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
      model = "kiro-claude-sonnet-5-agentic";
      env = {
        ANTHROPIC_BASE_URL = "https://cliproxyapi.${gatewayDomain}";
        ANTHROPIC_AUTH_TOKEN = "not-required";
        ANTHROPIC_DEFAULT_SONNET_MODEL = "kiro-claude-sonnet-5-agentic";
        ANTHROPIC_DEFAULT_OPUS_MODEL = "kiro-claude-opus-5-5-agentic";
        ANTHROPIC_DEFAULT_HAIKU_MODEL = "kiro-claude-haiku-4-5-agentic";
        DISABLE_AUTOUPDATER = "1";
      };
    };
  };
}
