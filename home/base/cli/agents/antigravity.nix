{ pkgs, ... }:

let
  gatewayDomain = (import ../../../../modules/server/lib.nix).domain;
in
{
  programs.antigravity-cli = {
    enable = true;
    package = pkgs.callPackage ./agy-cli.nix { };
    mutableSettings = true;
    settings.modelProvider = "gemini";
  };

  home.sessionVariables = {
    GOOGLE_GEMINI_BASE_URL = "https://cliproxyapi.${gatewayDomain}";
    GEMINI_API_KEY = "not-required";
  };
}
