{ pkgs, ... }:

{
  home.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    XDG_SESSION_TYPE = "wayland";
    XDG_CURRENT_DESKTOP = "Hyprland";
    XDG_SESSION_DESKTOP = "Hyprland";
    XDG_PICTURES_DIR = "$HOME/Pictures/Screenshots/";
    QT_QPA_PLATFORM = "wayland;xcb";
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
    QT_AUTO_SCREEN_SCALE_FACTOR = "1";
    GDK_BACKEND = "wayland,*";
    SDL_VIDEODRIVER = "wayland";
    CLUTTER_BACKEND = "wayland";
    MOZ_ENABLE_WAYLAND = "1";
    PATH = "./bin:$HOME/.local/bin:$PATH";
  };

  wayland.windowManager.hyprland = {
    enable = true;
    xwayland.enable = true;
    systemd = {
      enable = true;
      variables = [ "--all" ];
      enableXdgAutostart = true;
    };
    portalPackage = pkgs.xdg-desktop-portal-hyprland;

    settings = {
      # Variables
      "$browser" = "microsoft-edge";
      "$terminal" = "ghostty";
      "$editor" = "code";
      "$music" = "spotify";
      "$note" = "obsidian";
      "$fileManager" = "nautilus";

      # General settings
      general = {
        gaps_in = 1;
        gaps_out = 2;
        border_size = 0;
        resize_on_border = true;
        no_focus_fallback = true;
        allow_tearing = false;
        layout = "dwindle";
      };

      dwindle = {
        pseudotile = true;
        preserve_split = true;
      };

      decoration = {
        rounding = 12;

        blur = {
          enabled = false;
        };

        shadow = {
          enabled = false;
        };

        active_opacity = 0.9;
        inactive_opacity = 0.8;
        fullscreen_opacity = 1.0;

        dim_inactive = false;
        dim_strength = 0.1;
        dim_special = 0;
      };

      animations = {
        enabled = true;

        bezier = [
          "easeOutQuint,0.23,1,0.32,1"
          "easeInOutCubic,0.65,0.05,0.36,1"
          "linear,0,0,1,1"
          "almostLinear,0.5,0.5,0.75,1.0"
          "quick,0.15,0,0.1,1"
        ];

        animation = [
          "global, 1, 10, default"
          "border, 1, 5.39, easeOutQuint"
          "windows, 1, 4.79, easeOutQuint"
          "windowsIn, 1, 4.1, easeOutQuint, popin 87%"
          "windowsOut, 1, 1.49, linear, popin 87%"
          "fadeIn, 1, 1.73, almostLinear"
          "fadeOut, 1, 1.46, almostLinear"
          "fade, 1, 3.03, quick"
          "layers, 1, 3.81, easeOutQuint"
          "layersIn, 1, 4, easeOutQuint, fade"
          "layersOut, 1, 1.5, linear, fade"
          "fadeLayersIn, 1, 1.79, almostLinear"
          "fadeLayersOut, 1, 1.39, almostLinear"
          "workspaces, 0, 0, ease"
        ];
      };

      input = {
        kb_layout = "us";
        kb_options = "caps:escape";
        numlock_by_default = true;
        repeat_delay = 250;
        repeat_rate = 35;
        special_fallthrough = true;
        follow_mouse = 1;
      };

      device = {
        name = "compx-vxe-mouse-1k-dongle-1";
        sensitivity = -0.8;
      };

      binds = {
        scroll_event_delay = 0;
      };

      misc = {
        vfr = true;
        vrr = 1;
        animate_manual_resizes = false;
        animate_mouse_windowdragging = false;
        enable_swallow = false;
        disable_hyprland_logo = true;
        disable_splash_rendering = true;
        force_default_wallpaper = 0;
        allow_session_lock_restore = true;
        initial_workspace_tracking = false;
      };

      xwayland = {
        force_zero_scaling = true;
      };

      ecosystem = {
        no_update_news = true;
      };

      # Keybinds
      bindel = [
        ",XF86AudioRaiseVolume, exec, hypr-volume up"
        ",XF86AudioLowerVolume, exec, hypr-volume down"
        ",XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
        ",XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
        ",XF86MonBrightnessUp, exec, hypr-brightness up"
        ",XF86MonBrightnessDown, exec, hypr-brightness down"
      ];

      bindl = [
        ", switch:[Lid Switch], exec, hyprlock"
      ];

      bind = [
        "ALT, 1, exec, $browser"
        "ALT, 2, exec, $terminal"
        "ALT, 3, exec, $editor"
        "ALT, 4, exec, $note"
        "ALT, 5, exec, $music"
        "ALT, 6, exec, $fileManager"
        "CTRL, SPACE, exec, rofi -show combi -normal-window"
        "SUPER, F, togglefloating,"
        "SUPER, I, setprop, active opaque toggle"
        "SUPER, C, exec, rofi -show calc -modi calc -no-show-match -no-sort -calc-command \"echo -n '{result}' | wl-copy\""
        "SUPER, P, exec, rofi-playerctl"
        "SUPER, S, exec, rofi-session"
        "SUPER, T, exec, rofi-todoist"
        "SUPER, R, exec, rofi-change-theme"
        "SUPER, V, exec, copyq -e \"toggle()\""
        "SUPER, W, killactive,"
        "SUPER SHIFT, A, exec, hyprshot -m region --raw | swappy -f -"
        "SUPER SHIFT, S, exec, hyprshot -m region"
        "SUPER SHIFT, W, exec, hyprshot -m window"
        "SUPER, h, movefocus, l"
        "SUPER, l, movefocus, r"
        "SUPER, k, movefocus, u"
        "SUPER, j, movefocus, d"
        "SUPER, 1, workspace, 1"
        "SUPER, 2, workspace, 2"
        "SUPER, 3, workspace, 3"
        "SUPER, 4, workspace, 4"
        "SUPER, 5, workspace, 5"
        "SUPER, 6, workspace, 6"
        "SUPER, 7, workspace, 7"
        "SUPER, 8, workspace, 8"
        "SUPER, 9, workspace, 9"
        "SUPER, 0, workspace, 10"
        "SUPER SHIFT, N, workspace, e+1"
        "SUPER SHIFT, P, workspace, e-1"
        "SUPER SHIFT, L, workspace, previous"
        "SUPER SHIFT, 1, movetoworkspace, 1"
        "SUPER SHIFT, 2, movetoworkspace, 2"
        "SUPER SHIFT, 3, movetoworkspace, 3"
        "SUPER SHIFT, 4, movetoworkspace, 4"
        "SUPER SHIFT, 5, movetoworkspace, 5"
        "SUPER SHIFT, 6, movetoworkspace, 6"
        "SUPER SHIFT, 7, movetoworkspace, 7"
        "SUPER SHIFT, 8, movetoworkspace, 8"
        "SUPER SHIFT, 9, movetoworkspace, 9"
        "SUPER SHIFT, 0, movetoworkspace, 10"
        "SUPER SHIFT, right, movewindow, mon:+1"
        "SUPER SHIFT, left, movewindow, mon:-1"
        ", F11, fullscreen"
        ", F9, pass, class:^(com.obsproject.Studio)$"
        ", F10, pass, class:^(com.obsproject.Studio)$"
      ];

      bindm = [
        "SUPER, Control_L, movewindow"
        "SUPER, ALT_L, resizewindow"
      ];

      # Window rules
      windowrule = [
        "match:class (.*), float on"
        "match:class (.*), center on"
        "match:class (.*), size 95% 95%"
        "match:class ^(microsoft-edge)$, workspace 1"
        "match:class ^(com.mitchellh.ghostty|org.pwmt.zathura)$, workspace 2"
        "match:class ^(code|jetbrains-datagrip|libreoffice.*)$, workspace 3"
        "match:class ^(obsidian)$, workspace 4"
        "match:class ^(spotify)$, workspace 5"
        "match:class ^(org.gnome.Nautilus)$, workspace 6"
        "match:class ^(com.obsproject.Studio)$, workspace 7"
        "match:class ^(microsoft-edge|com.mitchellh.ghostty|org.pwmt.zathura|code|libreoffice.*|spotify|obsidian|org.gnome.Nautilus|com.obsproject.Studio)$, tile on"
        "match:class ^(obsidian|microsoft-edge|org.gnome.NautilusPreviewer|org.pwmt.zathura)$, opacity 1 override"
      ];
    };
  };
}
