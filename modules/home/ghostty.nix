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

      # Theme colors - imported from pywal-generated theme file
      # This file is managed by pywal and symlinked via dotfiles.nix
      config-file = "~/.config/ghostty/theme";
    };
  };
}
