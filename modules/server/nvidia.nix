{
  pkgs,
  config,
  lib,
  ...
}:

{
  # Register the NVIDIA driver without running a display server.
  # nixpkgs uses this to enable hardware.nvidia; required by nvidia-container-toolkit.
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    open = true;
    nvidiaSettings = false;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    modesetting.enable = true;
  };

  hardware.nvidia-container-toolkit.enable = true;

  systemd.services.nvidia-container-toolkit-cdi-generator = {
    # CDI generation often fails during switch before the new kernel module is
    # loaded. Don't block docker on it; retry until NVML comes up after reboot.
    requiredBy = lib.mkForce [ ];
    serviceConfig = {
      ExecStartPre = lib.mkForce null;
      Restart = "on-failure";
      RestartSec = "30s";
    };
  };

  environment.systemPackages = with pkgs; [
    nvtopPackages.nvidia
  ];
}
