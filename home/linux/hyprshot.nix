{ pkgs, config, ... }:

{
  programs.hyprshot = {
    enable = true;
    saveLocation = "$HOME/Pictures/Screenshots";
  };

  home.packages = with pkgs; [
    hyprpicker
    grim
    slurp
    swappy
  ];
}
