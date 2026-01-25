{ pkgs, lib, config, ... }:

# NixOS Desktop host configuration

{
  imports = [
    ./hardware-configuration.nix
    ./nvidia.nix  # Include NVIDIA module for this host
    ../../modules/nixos
  ];

  # Hostname
  networking.hostName = "nixos-desktop";

  # Host-specific overrides can go here
  # For example, if you need different settings for this particular machine
}
