{ pkgs, ... }:

{
  programs.antigravity-cli = {
    enable = true;
    package = pkgs.callPackage ./agy-cli.nix { };
    enableMcpIntegration = true;
    mutableSettings = true;
  };
}
