{
  pkgs,
  user,
  ...
}:

{
  # Boot configuration
  boot = {
    loader = {
      systemd-boot.enable = true;
      systemd-boot.configurationLimit = 10;
      efi.canTouchEfiVariables = true;
    };

    # Enable latest kernel for better hardware support
    kernelPackages = pkgs.linuxPackages_latest;
    growPartition = true;
  };

  # Timezone and locale
  time.timeZone = "America/New_York";

  # User configuration
  users.users.${user} = {
    isNormalUser = true;
    description = user;
    extraGroups = [
      "wheel"
      "docker"
    ];
    shell = pkgs.zsh;
  };

  # Enable zsh system-wide
  programs = {
    zsh.enable = true;
    fuse.userAllowOther = true;
  };

  # System state version
  system.stateVersion = "26.05";
}
