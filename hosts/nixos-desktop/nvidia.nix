{ pkgs, lib, config, ... }:

{
  # NVIDIA driver configuration
  # Note: This module should be imported only on hosts with NVIDIA GPUs

  # Enable OpenGL
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # NVIDIA driver
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    # Modesetting is required for Wayland
    modesetting.enable = true;

    # Power management (experimental)
    powerManagement.enable = false;
    powerManagement.finegrained = false;

    # Use the open source kernel module (for Turing and newer GPUs)
    # Set to false if you have an older GPU
    open = true;

    # Enable nvidia-settings GUI
    nvidiaSettings = true;

    # Use the latest stable driver
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  # NVIDIA-specific environment variables for Wayland/Hyprland
  environment.sessionVariables = {
    # Force GBM backend
    GBM_BACKEND = "nvidia-drm";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";

    # Cursor fix for NVIDIA
    WLR_NO_HARDWARE_CURSORS = "1";

    # Enable DRM kernel mode setting
    LIBVA_DRIVER_NAME = "nvidia";
  };

  # Kernel parameters for NVIDIA
  boot.kernelParams = [
    "nvidia-drm.modeset=1"
    "nvidia-drm.fbdev=1"
  ];

  # Load NVIDIA modules early
  boot.initrd.kernelModules = [ "nvidia" "nvidia_modeset" "nvidia_uvm" "nvidia_drm" ];
}
