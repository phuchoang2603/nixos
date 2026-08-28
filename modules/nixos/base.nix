{
  pkgs,
  user,
  ...
}:

{
  boot.kernelModules = [ "uinput" ];

  networking.networkmanager.enable = true;

  users.users.${user} = {
    isNormalUser = true;
    description = user;
    extraGroups = [
      "networkmanager"
      "wheel"
      "input"
      "uinput"
      "video"
      "audio"
    ];
    shell = pkgs.zsh;
  };

  fonts.fontconfig.enable = true;
}
