{ lib, pkgs, ... }:

{
  imports = [
    ./traefik.nix
    ./vaultwarden.nix
    ./karakeep.nix
    ./cloudflared.nix
    ./cliproxyapi.nix
    ./apply-browser.nix
  ];

  _module.args.lab = import ./lab.nix { inherit lib pkgs; };
}
