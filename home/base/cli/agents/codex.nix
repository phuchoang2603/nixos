{ ... }:

let
  gatewayDomain = (import ../../../../modules/server/lib.nix).domain;
in
{
  programs.codex = {
    enable = true;
    enableMcpIntegration = true;
    # Keep login/auth and interactive tweaks; declared settings still win on conflict.
    mutableSettings = true;
    settings = {
      model_provider = "cliproxyapi";
      model_providers.cliproxyapi = {
        name = "CLIProxyAPI";
        base_url = "https://cliproxyapi.${gatewayDomain}/v1";
        wire_api = "responses";
        requires_openai_auth = false;
      };
      sandbox_mode = "workspace-write";
    };
  };
}
