{ pkgs, lib, config, ... }:

# macOS MacBook host configuration placeholder
# TODO: Expand when setting up macOS

{
  imports = [
    ../../modules/darwin
  ];

  # Hostname
  networking.hostName = "macbook";

  # Host-specific overrides for MacBook
}
