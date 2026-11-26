{ lib, pkgs, ... }:

{
  imports = [
    ./traefik.nix
    ./vaultwarden.nix
    ./karakeep.nix
    ./newt.nix
    ./cliproxyapi.nix
    ./siyuan.nix
    ./t3code.nix
  ];

  _module.args.lab = import ./lab.nix { inherit lib pkgs; };
}
