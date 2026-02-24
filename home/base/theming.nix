{ pkgs, lib, ... }:

let
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
  wallpaperPath = ../../current.png;
in
{
  stylix = {
    enable = true;
    image = wallpaperPath;
    polarity = "dark";

    # Cursor: Only enable on Linux
    cursor = lib.mkIf (!isDarwin) {
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Classic";
      size = 16;
    };

    fonts = {
      monospace = {
        name = "CaskaydiaMono Nerd Font";
        package = pkgs.nerd-fonts.caskaydia-mono;
      };
      sansSerif = {
        name = "Noto Sans";
        package = pkgs.noto-fonts;
      };
      serif = {
        name = "Noto Serif";
        package = pkgs.noto-fonts;
      };
      emoji = {
        name = "Noto Color Emoji";
        package = pkgs.noto-fonts-color-emoji;
      };
      sizes = {
        applications = 12;
        terminal = 10;
        desktop = 10;
        popups = 12;
      };
    };

    # Icons: Only enable on Linux
    icons = lib.mkIf (!isDarwin) {
      enable = true;
      package = pkgs.papirus-icon-theme;
      dark = "Papirus-Dark";
      light = "Papirus-Light";
    };

    targets = {
      neovim = {
        enable = false;
      };
      rofi = {
        enable = false;
      };
      waybar = {
        enable = false;
      };
    };
  };
}
