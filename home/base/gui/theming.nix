{ pkgs, lib, config, ... }:

let
  userWallpaper = "${config.xdg.dataHome}/backgrounds/current.png";
  defaultWallpaper = ../../../current.png;
  wallpaperPath =
    if builtins.pathExists userWallpaper then userWallpaper else defaultWallpaper;
in
{
  stylix = {
    enable = true;
    image = wallpaperPath;
    polarity = "dark";
    
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
    
    targets = {
      neovim = {
        enable = true;
        plugin = "base16-nvim";
      };
      rofi = {
        enable = false;  # We'll use our custom rofi.nix instead
      };
      waybar = {
        enable = false;  # We'll use our custom waybar.nix instead
      };
    };
  };

  home.activation.ensureWallpaper =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if [ ! -f "${userWallpaper}" ]; then
        ${pkgs.coreutils}/bin/install -Dm644 "${defaultWallpaper}" "${userWallpaper}"
      fi
    '';
}
