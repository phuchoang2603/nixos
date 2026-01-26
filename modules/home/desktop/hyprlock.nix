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

      background = {
        path = "${config.home.homeDirectory}/.config/nix/current.png";
        blur_passes = 3;
        brightness = 0.4;
      };

      input-field = [
        { monitor = ""; }
        { size = "20%, 5%"; }
        { outline_thickness = 3; }
        { fade_on_empty = false; }
        { rounding = 15; }
        { placeholder_text = "Input password..."; }
        { fail_text = "$PAMFAIL"; }
        { dots_spacing = 0.3; }
        { position = "0, -150"; }
        { halign = "center"; }
        { valign = "center"; }
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
