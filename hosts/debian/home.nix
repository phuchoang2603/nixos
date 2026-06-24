{ user, ... }:

{
  home = {
    homeDirectory = "/home/${user}";
    username = user;
  };

  imports = [
    ../../home/base/cli.nix
    ../../home/base/gui.nix
  ];
}
