{
  lib,
  ...
}:

{
  programs.alacritty = {
    enable = true;
    settings = {
      # Font configuration
      font = {
        normal = {
          family = "CaskaydiaMono Nerd Font";
          style = "Regular";
        };
      };

      # Window settings
      window = {
        decorations = "None"; # Equivalent to window-decoration = false
        opacity = lib.mkForce 0.9;
        padding = {
          x = 10;
          y = 10;
        };
      };
    };
  };
}
