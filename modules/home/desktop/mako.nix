{ pkgs, lib, config, ... }:

{
  services.mako = {
    enable = true;

    settings = {
      backgroundColor = "#${config.lib.stylix.colors.base00}DD";  # with transparency
      textColor = "#${config.lib.stylix.colors.base05}";
      borderColor = "#${config.lib.stylix.colors.base0A}";
      width = 420;
      height = 110;
      padding = 8;
      margin = 2;
      borderSize = 1;
      borderRadius = 12;
      font = "CaskaydiaMono Nerd Font 11";
      anchor = "top-center";
      defaultTimeout = 5000;
      icons = true;
      maxIconSize = 32;
    };
  };
}
