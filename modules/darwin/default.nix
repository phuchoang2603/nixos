{ pkgs, lib, ... }:

{
  imports = [
    ./system.nix
    ./homebrew.nix
  ];
}
