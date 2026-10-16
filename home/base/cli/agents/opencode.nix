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
      # Plain serve (no --service): OpenCode only requires a password when
      # OPENCODE_SERVER_PASSWORD is set. Traefik reaches the host via
      # host.docker.internal, so bind on all interfaces.
      extraArgs = [
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
