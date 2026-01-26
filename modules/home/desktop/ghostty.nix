{ pkgs, lib, config, ... }:

{
  programs.ghostty = {
    enable = true;

    settings = {
      # Font configuration
      font-family = "CaskaydiaMono Nerd Font";
      font-size = 13;

      # Shell - use zsh from the system
      command = "zsh";

      # Window settings
      confirm-close-surface = false;
      window-decoration = false;
      window-padding-x = 10;
      window-padding-y = 10;

      # Colors managed by Stylix - no config-file needed
    };
  };
}
