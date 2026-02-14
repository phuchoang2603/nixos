{
  pkgs,
  lib,
  config,
  ...
}:

{
  services.mako = {
    enable = true;

    settings = {
      width = 420;
      height = 110;
      padding = 8;
      margin = 2;
      border-size = 1;
      border-radius = 12;
      anchor = "top-center";
      default-timeout = 5000;
      icons = true;
      max-icon-size = 32;
    };
  };

  services.copyq.enable = true;
}
