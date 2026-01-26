{ pkgs, lib, config, ... }:

{
  programs.waybar = {
    enable = true;
    
    settings = [{
      layer = "top";
      position = "top";
      height = 24;
      output = [
        "eDP-1"
        "HDMI-A-1"
        "DP-1"
      ];
      
      modules-left = [ "hyprland/workspaces" ];
      modules-center = [ "clock" ];
      modules-right = [ "pulseaudio" "memory" "battery" "tray" ];
      
      "hyprland/workspaces" = {
        format = "{icon}";
        format-icons = {
          default = "";
          active = "";
          urgent = "";
        };
        on-click = "activate";
        on-scroll-up = "hyprctl dispatch workspace e+1";
        on-scroll-down = "hyprctl dispatch workspace e-1";
      };

      "clock" = {
        format = "{:%H:%M}";
        tooltip-format = "{:%Y-%m-%d | %A}";
      };

      "pulseaudio" = {
        format = "{icon} {volume}%";
        format-bluetooth = "{icon} {volume}%";
        format-muted = "";
        format-icons = {
          headphone = "";
          hands-free = "";
          headset = "";
          phone = "";
          portable = "";
          car = "";
          default = [ "" "" "" ];
        };
        on-click = "pavucontrol";
      };

      "memory" = {
        interval = 30;
        format = "󰍛 {percentage}%";
      };

      "battery" = {
        states = {
          warning = 30;
          critical = 15;
        };
        format = "{icon} {capacity}%";
        format-charging = "⚡ {capacity}%";
        format-plugged = " {capacity}%";
        format-icons = [ "" "" "" "" "" ];
      };

      "tray" = {
        icon-size = 16;
        spacing = 8;
      };

      "custom-docker" = {
        exec = "$HOME/.config/nix/scripts/waybar-docker.sh";
        format = "{}";
        return-type = "json";
        interval = 5;
      };

      "custom-todoist" = {
        exec = "$HOME/.config/nix/scripts/waybar-todoist.sh";
        format = "󱸚 {}";
        return-type = "json";
        interval = 300;
      };
    }];

    style = let
      inherit (config.lib.stylix) colors;
    in ''
      * {
        font-family: CaskaydiaMono Nerd Font;
        font-weight: 700;
        font-size: 14px;
        color: #${colors.base05};
      }

      window#waybar {
        background: transparent;
        border: 0px;
      }

      #clock,
      #custom-docker,
      #custom-todoist,
      #workspaces button,
      #pulseaudio,
      #memory,
      #battery,
      #tray,
      #custom-pulse,
      #network {
        background-color: #${colors.base00};
        border: 1px solid #${colors.base0A};
        color: #${colors.base0A};
        margin: 2px;
        padding: 4px 8px;
        border-radius: 12px;
      }

      #clock,
      #workspaces button.active {
        background-color: #${colors.base0A};
        border: 1px solid #${colors.base00};
        color: #${colors.base00};
      }

      #pulseaudio,
      #memory,
      #battery {
        margin-left: 8px;
      }

      #workspaces button.active {
        padding: 4px 36px;
      }

      #workspaces button:hover {
        background-color: #${colors.base01};
      }

      tooltip {
        background-color: #${colors.base00};
        border: 1px solid #${colors.base0A};
        padding: 2px;
      }

      tooltip label {
        color: #${colors.base0A};
        padding: 2px;
      }
    '';
  };
}