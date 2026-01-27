{
  pkgs,
  lib,
  config,
  ...
}:

{
  programs.waybar = {
    enable = true;

    systemd.enable = true;

    settings = [
      {
        layer = "top";
        position = "top";
        spacing = 0;
        height = 0;
        output = "HDMI-A-1";
        margin-top = 2;

        modules-left = [
          "clock"
          "custom/todoist"
          "custom/docker"
        ];
        modules-center = [ "hyprland/workspaces" ];
        modules-right = [
          "mpris"
          "tray"
          "group/system"
        ];

        "hyprland/workspaces" = {
          disable-scroll = true;
          all-outputs = true;
          tooltip = false;
        };

        "clock" = {
          format = " {:%H:%M - %a, %b %d}";
          tooltip = true;
          tooltip-format = "";
          on-click = "gnome-calendar";
        };

        "cpu" = {
          format = "󰍛 {avg_frequency}GHz";
          interval = 5;
          states = {
            critical = 60;
          };
          tooltip = true;
          on-click = "gnome-system-monitor";
        };

        "memory" = {
          format = "  {used:0.1f}GB";
          interval = 15;
          tooltip = true;
          tooltip-format = "Used: {used:0.1f}GB / {total:0.1f}GB\nSwap: {swapUsed:0.1f}GB / {swapTotal:0.1f}GB";
          on-click = "gnome-system-monitor";
        };

        "pulseaudio" = {
          format = " {volume}%";
          format-muted = "󰝟 muted";
          scroll-step = 5;
          on-click = "pavucontrol";
          tooltip-format = "Playing at {volume}%";
          ignored-sinks = [ "Easy Effects Sink" ];
        };

        "battery" = {
          format = "{icon} {capacity}%";
          format-discharging = "{icon} {capacity}%";
          format-charging = "{icon} {capacity}%";
          format-plugged = "";
          format-icons = {
            charging = [
              "󰢜"
              "󰂆"
              "󰂇"
              "󰂈"
              "󰢝"
              "󰂉"
              "󰢞"
              "󰂊"
              "󰂋"
              "󰂅"
            ];
            default = [
              "󰁺"
              "󰁻"
              "󰁼"
              "󰁽"
              "󰁾"
              "󰁿"
              "󰂀"
              "󰂁"
              "󰂂"
              "󰁹"
            ];
          };
          format-full = "Charged ";
          tooltip-format-discharging = "{power:>1.0f}W↓ {capacity}%";
          tooltip-format-charging = "{power:>1.0f}W↑ {capacity}%";
          interval = 5;
          states = {
            warning = 20;
            critical = 10;
          };
        };

        "group/system" = {
          orientation = "inherit";
          modules = [
            "cpu"
            "memory"
            "pulseaudio"
            "battery"
          ];
        };

        "mpris" = {
          format = "{status_icon} {dynamic}";
          dynamic-len = 15;
          dynamic-separator = " - ";
          dynamic-order = [
            "title"
            "artist"
            "album"
          ];
          dynamic-importance-order = [
            "title"
            "artist"
            "album"
          ];
          status-icons = {
            playing = "";
            paused = "";
            stopped = "";
          };
          player = "spotify";
          on-click = "playerctl play-pause --player=spotify";
          enable-tooltip-len-limits = true;
        };

        "tray" = {
          spacing = 8;
          tooltip = false;
        };

        "custom/docker" = {
          format = "🐳 {}";
          return-type = "json";
          exec = "waybar-docker.sh";
          interval = 15;
          tooltip = true;
          on-click = "ghostty -e lazydocker";
        };

        "custom/todoist" = {
          format = " {}";
          return-type = "json";
          exec = "waybar-todoist.sh";
          interval = 60;
          tooltip = true;
        };
      }
    ];

    style =
      let
        inherit (config.lib.stylix) colors;
      in
      ''
        * {
          font-family: CaskaydiaMono Nerd Font;
          font-weight: 700;
          font-size: 14px;
        }

        window#waybar {
          background: transparent;
          border: 0px;
        }

        #clock,
        #custom-docker,
        #custom-todoist,
        #workspaces button,
        #mpris,
        #tray,
        #system {
          background-color: #${colors.base00};
          border: 1px solid #${colors.base0A};
          color: #${colors.base0A};
          margin: 2px;
          padding: 4px 8px;
          border-radius: 12px;
        }

        #clock,
        #system,
        #workspaces button.active {
          background-color: #${colors.base0A};
          border: 1px solid #${colors.base00};
          color: #${colors.base00};
        }

        #memory,
        #pulseaudio,
        #battery {
          margin-left: 8px;
        }

        #workspaces button.active {
          padding: 4px 36px;
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
