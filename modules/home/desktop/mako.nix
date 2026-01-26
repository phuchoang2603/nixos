{ pkgs, lib, config, ... }:

{
  services.mako = {
    enable = true;

    settings = {
      width = 420;
      height = 110;
      padding = 8;
      margin = 2;
      borderSize = 1;
      borderRadius = 12;
      anchor = "top-center";
      defaultTimeout = 5000;
      icons = true;
      maxIconSize = 32;
    };
  };
}
