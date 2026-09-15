{
  config,
  lib,
  ...
}:

{
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    open = true;
    nvidiaSettings = false;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    modesetting.enable = true;
  };

  hardware.nvidia-container-toolkit.enable = true;

  # CDI generation talks to the loaded nvidia.ko. After a kernel/driver
  # bump that module is still the old one until reboot, so nvidia-ctk fails
  # and nixos-rebuild switch treats the failed unit as activation failure.
  # Leave the previous CDI spec in place; the udev rule regenerates it on boot.
  systemd.services.nvidia-container-toolkit-cdi-generator = {
    requiredBy = lib.mkForce [ ];
    restartIfChanged = false;
    stopIfChanged = false;
  };
}
