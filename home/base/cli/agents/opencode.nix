{
  inputs,
  pkgs,
  ...
}:

let
  gatewayDomain = (import ../../../../modules/server/lib.nix).domain;
in
{
  programs.opencode = {
    enable = true;
    package = pkgs.callPackage "${inputs.opencode-nixpkgs}/pkgs/by-name/op/opencode/package.nix" { };
    enableMcpIntegration = true;
    mutableSettings = true;
    # Remote schema $refs break Nix/CI builds.
    validateFiles.config = false;
    web = {
      enable = true;
      # Shared service so `opencode service get password` matches Traefik :4096.
      extraArgs = [
        "--service"
        "--hostname"
        "0.0.0.0"
        "--port"
        "4096"
      ];
    };
    settings = {
      model = "openai/gpt-6.1-sol";
      provider.openai = {
        name = "CLIProxyAPI";
        options = {
          baseURL = "https://cliproxyapi.${gatewayDomain}/v1";
          # The gateway does not require authentication; the SDK expects a key.
          apiKey = "unused";
        };
      };
    };
  };
}
