{ pkgs, ... }:

{
  imports = [
    ../base
    ./aerospace.nix
  ];

  home.packages = with pkgs; [
    raycast
  ];
}
