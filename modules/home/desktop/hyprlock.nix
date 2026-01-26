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

      label = [
        {
          text = "$TIME";
          position = "0, -150";
          halign = "center";
          valign = "top";
        }
        {
          text = "cmd[update:60000] date +\"%A, %d %B %Y\"";
          position = "0, -300";
          halign = "center";
          valign = "top";
        }
      ];
    };
  };
}
