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
    # Schema validation pulls https://models.dev/model-schema.json at build time,
    # which fails in the Nix sandbox / CI.
    validateFiles.config = false;
    web = {
      enable = true;
      extraArgs = [
        # Shared background service on localhost; remote access uses OpenTunnel
        # (`opencode pair --remote`), not Traefik/Pangolin.
        "--service"
        "--hostname"
        "127.0.0.1"
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
