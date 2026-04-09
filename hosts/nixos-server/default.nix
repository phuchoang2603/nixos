{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/base.nix
    ../../modules/nixos/server-services.nix
    ../../modules/nixos/nvidia.nix
  ];

  networking.hostName = "nixos-server";
}
