{
  imports = [
    ./traefik.nix
    ./vaultwarden.nix
    ./karakeep.nix
    ./newt.nix
    ./socat.nix
    ./cliproxyapi.nix
    ./executor.nix
    ./obscura.nix
    ./excalidraw.nix
  ];

  _module.args.lab = import ./lab.nix;
}
