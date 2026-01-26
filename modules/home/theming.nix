{ pkgs, ... }:

{
  stylix = {
    enable = true;
    image = ../../current.png;
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
      rofi = {
        enable = false;  # We'll use our custom rofi.nix instead
      };
      mako = {
        enable = false;  # We'll use our custom mako.nix instead
      };
      waybar = {
        enable = false;  # We'll use our custom waybar.nix instead
      };
      hyprlock = {
        enable = false;  # We'll use our custom hyprlock.nix instead
      };
    };
  };
}
