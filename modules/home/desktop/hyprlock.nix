{ pkgs, config, ... }:

{
  programs.hyprlock = {
    enable = true;
    
    settings = {
      general = {
        disable_loading_bar = true;
        no_fade_in = false;
      };

      animations = [
        { enabled = false; }
      ];
    };
  };
}
