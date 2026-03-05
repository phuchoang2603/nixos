{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/base.nix
    ../../modules/nixos/server-services.nix
  ];

  networking.hostName = "nixos-server";
}
