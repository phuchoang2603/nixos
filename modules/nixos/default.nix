{ pkgs, lib, ... }:

{
  imports = [
    ./system.nix
    ./desktop.nix
    ./apps.nix
    ./input-methods.nix
  ];
}
