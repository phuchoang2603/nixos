{ lib, pkgs, ... }:

{
  imports = [
    ./traefik.nix
    ./vaultwarden.nix
    ./karakeep.nix
    ./newt.nix
    ./cliproxyapi.nix
  ];

  _module.args.lab = import ./lab.nix { inherit lib pkgs; };
}
