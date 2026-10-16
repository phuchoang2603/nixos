{ config, ... }:

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

  # GPU containers provide their own CUDA libraries; only the host driver and
  # container integration are needed here.
}
