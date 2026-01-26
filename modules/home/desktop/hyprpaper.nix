{ pkgs, config, ... }:

{
  services.hyprpaper = {
    enable = true;
    
    settings = {
      wallpaper = [
        "monitor ="
        "path = ${config.home.homeDirectory}/.config/nix/current.png"
        "fit_mode = cover"
      ];
      
      splash = false;
    };
  };
}
