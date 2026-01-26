{ pkgs, config, ... }:

{
  programs.rofi = {
    enable = true;
    package = pkgs.rofi;
  };

  xdg.configFile."rofi/config.rasi".source = ./rofi-config/config.rasi;
  xdg.configFile."rofi/theme.rasi".source = ./rofi-config/theme.rasi;
  xdg.configFile."rofi/grid.rasi".source = ./rofi-config/grid.rasi;
  xdg.configFile."rofi/colors.rasi".text = let
    inherit (config.lib.stylix) colors;
  in ''
    * {
        background: #${colors.base00};
        background-alt: #${colors.base01};
        foreground: #${colors.base05};
        selected: #${colors.base0A};
        active: #${colors.base0B};
        urgent: #${colors.base08};
    }
  '';
}
