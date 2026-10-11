{ config, pkgs, ... }:

{
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    open = true;
    nvidiaSettings = false;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    modesetting.enable = true;
  };

  # Generates the CDI spec in /var/run/cdi; containers request the GPU with --device=nvidia.com/gpu=all.
  hardware.nvidia-container-toolkit.enable = true;

  environment.systemPackages = [ pkgs.cudaPackages.cudatoolkit ];
}
