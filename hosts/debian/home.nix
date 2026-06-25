{ user, ... }:

{
  home = {
    homeDirectory = "/home/${user}";
    username = user;
  };

  targets.genericLinux.enable = true;

  xdg.systemDirs.config = [
    "/etc/xdg"
    "/usr/share"
  ];

  imports = [
    ../../home/base/cli.nix
    ../../home/base/gui.nix
  ];
}
