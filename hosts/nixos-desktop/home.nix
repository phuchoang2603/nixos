{ ... }:

{
  my.waybar.output = "HDMI-A-1";
  my.rcloneBisync.enable = true;

  wayland.windowManager.hyprland.settings = {
    monitor = [
      "HDMI-A-1,1920x1080@60.0,0x342,1.0"
      "DP-1,1920x1080@60.0,1920x0,1.5"
      "DP-1,transform,1"
    ];
    workspace = [
      "1,monitor:HDMI-A-1"
      "2,monitor:HDMI-A-1"
      "3,monitor:HDMI-A-1"
      "4,monitor:HDMI-A-1"
      "5,monitor:HDMI-A-1"
      "6,monitor:HDMI-A-1"
      "7,monitor:HDMI-A-1"
      "8,monitor:HDMI-A-1"
      "9,monitor:HDMI-A-1"
      "10,monitor:HDMI-A-1"
    ];
  };
}
