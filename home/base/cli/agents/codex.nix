{ ... }:

{
  programs.codex = {
    enable = true;
    enableMcpIntegration = true;
    settings = {
      model_provider = "cliproxyapi";
      model_providers.cliproxyapi = {
        name = "CLIProxyAPI";
        base_url = "https://cliproxyapi.home.phuchoang.sbs/v1";
        wire_api = "responses";
        requires_openai_auth = false;
      };
    };
  };
}
