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

  # Don't block docker if CDI generation fails during switch (reboot after driver updates).
  systemd.services.nvidia-container-toolkit-cdi-generator.requiredBy = lib.mkForce [ ];
}
