{
  imports = [
    ./traefik.nix
    ./vaultwarden.nix
    ./karakeep.nix
    ./n8n.nix
    ./newt.nix
  ];

  _module.args.lab = import ./lab.nix;
}
