# This is a placeholder hardware-configuration.nix
#
# IMPORTANT: Do NOT use this file directly!
#
# When you install NixOS, run:
#   sudo nixos-generate-config --show-hardware-config > hardware-configuration.nix
#
# This will generate the correct configuration for your specific hardware,
# including:
#   - Filesystem mounts (root, boot, swap)
#   - Kernel modules for your hardware
#   - CPU microcode
#   - Any special hardware quirks
#
# Then copy that output to replace this file.

{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  # ============================================
  # REPLACE EVERYTHING BELOW WITH YOUR GENERATED CONFIG
  # ============================================

  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usbhid" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];  # or "kvm-intel" for Intel CPUs
  boot.extraModulePackages = [ ];

  # Example filesystem configuration - REPLACE WITH YOUR ACTUAL MOUNTS
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/boot";
    fsType = "vfat";
  };

  swapDevices = [
    { device = "/dev/disk/by-label/swap"; }
  ];

  # CPU microcode (uncomment the appropriate one)
  # hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  # hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  # Networking interface (will be auto-detected)
  # networking.useDHCP = lib.mkDefault true;

  # Platform
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
