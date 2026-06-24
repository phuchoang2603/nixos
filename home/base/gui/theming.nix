{ pkgs, lib, ... }:

let
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
in
{
  stylix = {
    enable = true;
    image = pkgs.fetchurl {
      url = "https://media.githubusercontent.com/media/phuchoang2603/nixos/refs/heads/main/wallpapers/orange-girl-nature.png";
      hash = "sha256-upZ9zonKq02fcvznWhUD+5Nn3WTgUuNMg9lUI9FV0DI=";
    };
    polarity = "dark";

    # Cursor: Only enable on Linux
    cursor = lib.mkIf (!isDarwin) {
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Classic";
      size = 16;
    };

    fonts = {
      monospace = {
        name = "CaskaydiaCove Nerd Font Mono";
        package = pkgs.nerd-fonts.caskaydia-cove;
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
        applications = 14;
        terminal = 16;
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
        enable = true;
        plugin = "base16-nvim";
        colors = {
          enable = true;
        };
        transparentBackground = {
          main = true;
          numberLine = true;
          signColumn = true;
        };
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
