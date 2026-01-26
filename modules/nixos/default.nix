{ pkgs, lib, ... }:

{
  imports = [
    ./system.nix
    ./desktop.nix
    ./system-apps.nix
    ./input-methods.nix
  ];
}
