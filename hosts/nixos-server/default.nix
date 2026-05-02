{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/server
  ];

  networking.hostName = "nixos-server";
}
