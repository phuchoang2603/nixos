{ pkgs, ... }:

let
  scriptDir = ./scripts;

  hyprBrightness = pkgs.writeShellApplication {
    name = "hypr-brightness";
    runtimeInputs = [
      pkgs.brightnessctl
      pkgs.coreutils
      pkgs.libnotify
    ];
    text = builtins.readFile (scriptDir + "/hypr-brightness.sh");
  };

  hyprVolume = pkgs.writeShellApplication {
    name = "hypr-volume";
    runtimeInputs = [
      pkgs.wireplumber
      pkgs.gawk
      pkgs.libnotify
    ];
    text = builtins.readFile (scriptDir + "/hypr-volume.sh");
  };

in
{
  home.packages = [
    hyprBrightness
    hyprVolume
  ];
}
