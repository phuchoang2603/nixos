{ pkgs, ... }:

{
  imports = [
    ../base/cli.nix
    ../base/gui.nix
    ./aerospace.nix
  ];
}
