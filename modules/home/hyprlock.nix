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
        monitor = "";
        path = "${config.home.homeDirectory}/.config/nix/current.png";
        blur_passes = 3;
        brightness = 0.4;
      };

      input-field = [
        { monitor = ""; }
        { size = "20%, 5%"; }
        { outline_thickness = 3; }
        { inner_color = "rgba(0, 0, 0, 0.0)"; }
        { outer_color = "rgba(255, 255, 255, 1)"; }
        { font_color = "rgba(255, 255, 255, 1)"; }
        { fade_on_empty = false; }
        { rounding = 15; }
        { font_family = "CaskaydiaMono Nerd Font"; }
        { placeholder_text = "Input password..."; }
        { fail_text = "$PAMFAIL"; }
        { dots_spacing = 0.3; }
        { position = "0, -150"; }
        { halign = "center"; }
        { valign = "center"; }
      ];

      label = [
        {
          monitor = "";
          text = "$TIME";
          color = "rgba(255, 255, 255, 1)";
          font_size = 90;
          font_family = "CaskaydiaMono Nerd Font";
          position = "0, -150";
          halign = "center";
          valign = "top";
        }
        {
          monitor = "";
          text = "cmd[update:60000] date +\"%A, %d %B %Y\"";
          color = "rgba(255, 255, 255, 1)";
          font_size = 25;
          font_family = "CaskaydiaMono Nerd Font";
          position = "0, -300";
          halign = "center";
          valign = "top";
        }
      ];
    };
  };
}