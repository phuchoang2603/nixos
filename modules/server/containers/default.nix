{ lib, pkgs, ... }:

{
  imports = [
    ./traefik.nix
    ./vaultwarden.nix
    ./karakeep.nix
    ./newt.nix
    ./omniroute.nix
    ./executor.nix
    ./excalidraw.nix
    ./hermes.nix
    ./hermes-desktop.nix
    ./hindsight.nix
    ./speaker.nix
    ./jellyfin.nix
    ./explo.nix
    ./audiomuse.nix
  ];

  _module.args.lab = import ./lab.nix { inherit lib pkgs; };
}
