{
  imports = [
    ./traefik.nix
    ./vaultwarden.nix
    ./karakeep.nix
    ./n8n.nix
    ./newt.nix
    ./suwayomi.nix
  ];

  _module.args.lab = import ./lab.nix;
}
