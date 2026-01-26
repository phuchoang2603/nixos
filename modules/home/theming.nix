{ pkgs, ... }:

{
  stylix = {
    enable = true;
    image = ../../current.png;
    polarity = "dark";
    
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
    };
  };
}
