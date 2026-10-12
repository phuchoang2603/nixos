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
    ./speaker.nix
    ./jellyfin.nix
    ./explo.nix
  ];

  _module.args.lab = import ./lab.nix;
}
