{ lib, pkgs, ... }:

{
  imports = [
    ./traefik.nix
    ./vaultwarden.nix
    ./karakeep.nix
    ./newt.nix
    ./cliproxyapi.nix
    ./executor.nix
    ./siyuan.nix
    ./hermes.nix
    ./hermes-desktop.nix
    ./hindsight.nix
  ];

  _module.args.lab = import ./lab.nix { inherit lib pkgs; };
}
