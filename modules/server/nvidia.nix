{
  pkgs,
  config,
  lib,
  ...
}:

let
  nvidiaDriver = config.hardware.nvidia.package;
  nvidiaToolkit = config.hardware.nvidia-container-toolkit.package;
  toolkitCfg = config.hardware.nvidia-container-toolkit;

  cdiGenerate = pkgs.writeShellScript "nvidia-cdi-generate" ''
    set -euo pipefail
    ${lib.getExe' nvidiaToolkit "nvidia-ctk"} cdi generate \
      --format json \
      --discovery-mode ${toolkitCfg.discovery-mode} \
      --device-name-strategy ${toolkitCfg.device-name-strategy} \
      ${lib.concatMapStringsSep " \\\n" (hook: "--disable-hook ${hook}") toolkitCfg.disable-hooks} \
      ${lib.concatMapStringsSep " \\\n" (hook: "--enable-hook ${hook}") toolkitCfg.enable-hooks} \
      --ldconfig-path ${lib.getExe' pkgs.glibc "ldconfig"} \
      --library-search-path ${lib.getLib nvidiaDriver}/lib \
      --nvidia-cdi-hook-path ${lib.getOutput "tools" nvidiaToolkit}/bin/nvidia-cdi-hook \
      ${lib.escapeShellArgs toolkitCfg.extraArgs} \
      --output="$1"
  '';

  cdiGenerateIfReady = pkgs.writeShellScript "nvidia-cdi-generate-if-ready" ''
    set -euo pipefail
    output="$1"

    if ! ${lib.getExe' nvidiaDriver "nvidia-smi"} >/dev/null 2>&1; then
      echo "NVML not ready (reboot after NVIDIA driver updates); skipping CDI generation"
      exit 0
    fi

    ${cdiGenerate} "$output"
  '';
in
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
    requiredBy = lib.mkForce [ ];
    serviceConfig = {
      ExecStartPre = lib.mkForce null;
      ExecStart = lib.mkForce "${cdiGenerateIfReady} /var/run/cdi/nvidia-container-toolkit.json";
      Type = "oneshot";
      RemainAfterExit = true;
      RuntimeDirectory = "cdi";
    };
  };

  # Regenerate CDI after boot once the new kernel module is loaded.
  systemd.services.nvidia-cdi-post-boot = {
    description = "Regenerate NVIDIA CDI spec after boot";
    wantedBy = [ "multi-user.target" ];
    after = [
      "systemd-modules-load.service"
      "network-online.target"
    ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${cdiGenerateIfReady} /var/run/cdi/nvidia-container-toolkit.json";
    };
  };

  environment.systemPackages = with pkgs; [
    nvtopPackages.nvidia
  ];
}
