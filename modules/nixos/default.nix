{ pkgs, lib, ... }:

{
  imports = [
    ./system.nix
    ./desktop.nix
    ./apps.nix
    ./services.nix
    ./input-methods.nix
  ];
}
