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
    ./hermes.nix
    ./hermes-desktop.nix
    ./hindsight.nix
    ./jellyfin.nix
    ./slskd.nix
    ./lidarr.nix
    ./arr.nix
    ./qbittorrent.nix
    ./flaresolverr.nix
    ./cantinarr.nix
    ./audiomuse.nix
  ];

  _module.args.lab = import ./lab.nix { inherit lib pkgs; };
}
