{ config, ... }:

let
  wallpaperPath = config.stylix.image;
in
{
  services.hyprpaper = {
    enable = true;

    settings = {
      wallpaper = [
        "monitor ="
        "path = ${wallpaperPath}"
        "fit_mode = cover"
      ];

      splash = false;
    };
  };
}
