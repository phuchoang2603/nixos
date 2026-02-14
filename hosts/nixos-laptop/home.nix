{ ... }:

{
  my.waybar.output = "eDP-1";

  wayland.windowManager.hyprland.settings = {
    monitor = [
      "eDP-1,1920x1080@60.0,0x342,1.0"
    ];

    workspace = [
      "1,monitor:eDP-1"
      "2,monitor:eDP-1"
      "3,monitor:eDP-1"
      "4,monitor:eDP-1"
      "5,monitor:eDP-1"
      "6,monitor:eDP-1"
      "7,monitor:eDP-1"
      "8,monitor:eDP-1"
      "9,monitor:eDP-1"
      "10,monitor:eDP-1"
    ];

    input = {
      kb_layout = "us";
      kb_options = "caps:escape";
      numlock_by_default = true;
      repeat_delay = 250;
      repeat_rate = 35;
      special_fallthrough = true;
      follow_mouse = 1;

      touchpad = {
        disable_while_typing = true;
        natural_scroll = true;
        scroll_factor = 0.3;
        clickfinger_behavior = true;
        tap-to-click = true;
        drag_lock = 1;
        tap-and-drag = true;
      };
    };

    gesture = [
      "2, right, dispatcher, sendshortcut, ALT, right, activewindow"
      "2, left, dispatcher, sendshortcut, ALT, left, activewindow"
      "3, right, dispatcher, sendshortcut, CTRL, Page_Down, activewindow"
      "3, left, dispatcher, sendshortcut, CTRL, Page_Up, activewindow"
      "3, up, dispatcher, sendshortcut, CTRL, T, activewindow"
      "3, down, dispatcher, sendshortcut, CTRL, W, activewindow"
      "4, horizontal, workspace"
      "4, pinch, dispatcher, setprop, active opaque toggle"
      "4, up, fullscreen"
      "4, down, close"
    ];

  };
}
