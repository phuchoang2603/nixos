{
  pkgs,
  config,
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

  environment.systemPackages = with pkgs; [
    nvtopPackages.nvidia
  ];
}
