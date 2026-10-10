{
  imports = [
    ./traefik.nix
    ./vaultwarden.nix
    ./karakeep.nix
    ./newt.nix
    ./cliproxyapi.nix
    ./executor.nix
    ./obscura.nix
    ./excalidraw.nix
    ./hermes.nix
  ];

  _module.args.lab = import ./lab.nix;
}
