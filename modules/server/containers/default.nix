{ lib, pkgs, ... }:

{
  imports = [
    ./traefik.nix
    ./vaultwarden.nix
    ./karakeep.nix
    ./newt.nix
    ./cliproxyapi.nix
    ./executor.nix
    ./excalidraw.nix
    ./siyuan.nix
    ./hermes.nix
    ./hermes-desktop.nix
    ./hindsight.nix
    ./media
  ];

  _module.args.lab = import ./lab.nix { inherit lib pkgs; };
}
