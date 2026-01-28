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

  rofiChangeTheme = pkgs.writeShellApplication {
    name = "rofi-change-theme";
    runtimeInputs = [
      pkgs.nh
      pkgs.rofi
      pkgs.findutils
      pkgs.gnugrep
      pkgs.coreutils
      pkgs.libnotify
    ];
    text = builtins.readFile (scriptDir + "/rofi-change-theme");
  };

  rofiPlayerctl = pkgs.writeShellApplication {
    name = "rofi-playerctl";
    runtimeInputs = [
      pkgs.rofi
      pkgs.playerctl
      pkgs.playerctld
      pkgs.coreutils
    ];
    text = builtins.readFile (scriptDir + "/rofi-playerctl");
  };

  rofiSession = pkgs.writeShellApplication {
    name = "rofi-session";
    runtimeInputs = [
      pkgs.rofi
      pkgs.playerctl
      pkgs.hyprlock
      pkgs.systemd
    ];
    text = builtins.readFile (scriptDir + "/rofi-session");
  };

  rofiTodoist = pkgs.writeShellApplication {
    name = "rofi-todoist";
    runtimeInputs = [
      pkgs.rofi
      pkgs.todoist
      pkgs.gawk
      pkgs.gnused
      pkgs.gnugrep
      pkgs.coreutils
      pkgs.libnotify
    ];
    text = builtins.readFile (scriptDir + "/rofi-todoist");
  };

  waybarDocker = pkgs.writeShellApplication {
    name = "waybar-docker";
    runtimeInputs = [
      pkgs.docker
      pkgs.coreutils
      pkgs.gnused
    ];
    text = builtins.readFile (scriptDir + "/waybar-docker.sh");
  };

  waybarTodoist = pkgs.writeShellApplication {
    name = "waybar-todoist";
    runtimeInputs = [
      pkgs.todoist
      pkgs.gawk
      pkgs.gnused
      pkgs.coreutils
    ];
    text = builtins.readFile (scriptDir + "/waybar-todoist.sh");
  };
in
{
  home.packages = [
    hyprBrightness
    hyprVolume
    rofiChangeTheme
    rofiPlayerctl
    rofiSession
    rofiTodoist
    waybarDocker
    waybarTodoist
  ];
}
