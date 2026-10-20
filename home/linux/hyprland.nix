{ pkgs, ... }:

{
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
      env = [
        "NIXOS_OZONE_WL,1"
        "XDG_SESSION_TYPE,wayland"
        "XDG_CURRENT_DESKTOP,Hyprland"
        "XDG_SESSION_DESKTOP,Hyprland"
        "XDG_PICTURES_DIR,$HOME/Pictures/Screenshots"
        "QT_QPA_PLATFORM,wayland;xcb"
        "QT_WAYLAND_DISABLE_WINDOWDECORATION,1"
        "QT_AUTO_SCREEN_SCALE_FACTOR,1"
        "GDK_BACKEND,wayland,*"
        "SDL_VIDEODRIVER,wayland"
        "CLUTTER_BACKEND,wayland"
        "MOZ_ENABLE_WAYLAND,1"
        "PATH,$HOME/.local/bin:$PATH"
      ];

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
        "ALT, SPACE, exec, vicinae toggle"
        "ALT, F, exec, vicinae vicinae://launch/files/search"
        "ALT SHIFT, F, togglefloating,"
        "ALT, I, setprop, active opaque toggle"
        "ALT, C, exec, vicinae 'vicinae://toggle?fallbackText=%3D'"
        "ALT, V, exec, vicinae vicinae://launch/clipboard/history"
        "ALT, W, exec, vicinae vicinae://launch/wm/switch-windows"
        "ALT SHIFT, A, exec, hyprshot -m region --raw | swappy -f -"
        "ALT SHIFT, S, exec, hyprshot -m region"
        "ALT SHIFT, W, exec, hyprshot -m window"
        "ALT, h, movefocus, l"
        "ALT, l, movefocus, r"
        "ALT, k, movefocus, u"
        "ALT, j, movefocus, d"
        "ALT, 1, workspace, 1"
        "ALT, 2, workspace, 2"
        "ALT, 3, workspace, 3"
        "ALT, 4, workspace, 4"
        "ALT, 5, workspace, 5"
        "ALT, 6, workspace, 6"
        "ALT, 7, workspace, 7"
        "ALT, 8, workspace, 8"
        "ALT, 9, workspace, 9"
        "ALT, 0, workspace, 10"
        "ALT SHIFT, N, workspace, e+1"
        "ALT SHIFT, P, workspace, e-1"
        "ALT, tab, workspace, previous"
        "ALT SHIFT, H, movewindow, l"
        "ALT SHIFT, L, movewindow, r"
        "ALT SHIFT, K, movewindow, u"
        "ALT SHIFT, J, movewindow, d"
        "ALT SHIFT, 1, movetoworkspace, 1"
        "ALT SHIFT, 2, movetoworkspace, 2"
        "ALT SHIFT, 3, movetoworkspace, 3"
        "ALT SHIFT, 4, movetoworkspace, 4"
        "ALT SHIFT, 5, movetoworkspace, 5"
        "ALT SHIFT, 6, movetoworkspace, 6"
        "ALT SHIFT, 7, movetoworkspace, 7"
        "ALT SHIFT, 8, movetoworkspace, 8"
        "ALT SHIFT, 9, movetoworkspace, 9"
        "ALT SHIFT, 0, movetoworkspace, 10"
        "ALT SHIFT, right, movewindow, mon:+1"
        "ALT SHIFT, left, movewindow, mon:-1"
        ", F11, fullscreen"
        ", F9, pass, class:^(com.obsproject.Studio)$"
        ", F10, pass, class:^(com.obsproject.Studio)$"
      ];

      bindm = [
        "ALT, Control_L, movewindow"
        "ALT, Shift_L, resizewindow"
      ];

      # Window rules
      windowrule = [
        "match:class (.*), float on"
        "match:class (.*), center on"
        "match:class (.*), size 95% 95%"
        "match:class ^(microsoft-edge)$, workspace 1"
        "match:class ^(com.mitchellh.ghostty)$, workspace 2"
        "match:class ^(code|jetbrains-datagrip|libreoffice.*)$, workspace 3"
        "match:class ^(obsidian)$, workspace 5"
        "match:class ^(org.gnome.Nautilus)$, workspace 6"
        "match:class ^(com.obsproject.Studio)$, workspace 7"
        "match:class ^(microsoft-edge|com.mitchellh.ghostty|code|libreoffice.*|obsidian|org.gnome.Nautilus|com.obsproject.Studio)$, tile on"
        "match:class ^(obsidian|microsoft-edge|org.gnome.NautilusPreviewer)$, opacity 1 override"
      ];
    };
  };
}
