let
  server = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKuZN2XPTYV7erg5JLdgSgOUytnj4g1vu3sYqq9PUnh+";
  macbook = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINOFe4vrl3REBGRpH4/7SbpH9fagoeeqf9ku2xxoEh1u";
  names = [
    "cliproxyapi.env"
    "hermes.env"
    "hindsight.env"
    "karakeep.env"
    "newt.env"
    "siyuan.env"
    "terraform-agent.env"
    "traefik.env"
    "vaultwarden.env"
  ];
in
builtins.listToAttrs (
  map (name: {
    name = "${name}.age";
    value.publicKeys = [
      server
      macbook
    ];
  }) names
)
