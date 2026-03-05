{
  pkgs,
  lib,
  config,
  ...
}:

# NixOS Desktop host configuration

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos
  ];

  # Hostname
  networking.hostName = "nixos-desktop";

  # Host-specific overrides can go here
  # For example, if you need different settings for this particular machine
}
