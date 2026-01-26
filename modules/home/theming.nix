{ pkgs, config, ... }:

{
  stylix = {
    enable = true;
    image = "${config.home.homeDirectory}/.config/nix/current.png";
    polarity = "dark";
  };
}