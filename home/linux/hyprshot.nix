{ pkgs, config, ... }:

{
  programs.hyprshot = {
    enable = true;
    saveLocation = "${config.home.homeDirectory}/Pictures/Screenshots";
  };

  home.packages = with pkgs; [
    hyprpicker
    grim
    slurp
    swappy
  ];
}
