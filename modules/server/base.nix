{
  pkgs,
  user,
  ...
}:

{
  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 8 * 1024;
    }
  ];

  users.users.${user} = {
    isNormalUser = true;
    description = user;
    linger = true;
    extraGroups = [
      "wheel"
      "docker"
    ];
    shell = pkgs.zsh;
  };
}
