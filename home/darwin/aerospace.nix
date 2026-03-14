{
  programs.aerospace = {
    enable = true;
    launchd.enable = true;

    settings = {
      "start-at-login" = true;
      "after-startup-command" = [ ];

      "enable-normalization-flatten-containers" = true;
      "enable-normalization-opposite-orientation-for-nested-containers" = true;

      "default-root-container-layout" = "accordion";
      "default-root-container-orientation" = "auto";

      "on-focused-monitor-changed" = [ "move-mouse monitor-lazy-center" ];
      "on-focus-changed" = [ "move-mouse window-lazy-center" ];

      "automatically-unhide-macos-hidden-apps" = true;

      "key-mapping" = {
        preset = "qwerty";
      };

      "workspace-to-monitor-force-assignment" = {
        "10" = "DELL P2317H";
      };

      gaps = {
        inner.horizontal = 2;
        inner.vertical = 4;
        outer.left = 4;
        outer.bottom = 4;
        outer.top = 4;
        outer.right = 4;
      };

      mode.main.binding = {
        # Workspace switch
        alt-1 = [
          "workspace 1"
          "exec-and-forget open -a 'Microsoft Edge'"
        ];
        alt-2 = [
          "workspace 2"
          "exec-and-forget open -a 'Ghostty'"
        ];
        alt-3 = "workspace 3";
        alt-4 = [
          "workspace 4"
          "exec-and-forget open -a 'Obsidian'"
        ];
        alt-5 = [
          "workspace 5"
          "exec-and-forget open -a 'Spotify'"
        ];
        alt-6 = [
          "workspace 6"
          "exec-and-forget open -a 'Finder'"
        ];
        alt-7 = "workspace 7";
        alt-8 = "workspace 8";
        alt-9 = "workspace 9";
        alt-0 = "workspace 10";

        # Focus
        alt-h = "focus --boundaries all-monitors-outer-frame --boundaries-action wrap-around-all-monitors left";
        alt-j = "focus --boundaries all-monitors-outer-frame --boundaries-action wrap-around-all-monitors down";
        alt-k = "focus --boundaries all-monitors-outer-frame --boundaries-action wrap-around-all-monitors up";
        alt-l = "focus --boundaries all-monitors-outer-frame --boundaries-action wrap-around-all-monitors right";

        # Move window
        alt-shift-h = "move left";
        alt-shift-j = "move down";
        alt-shift-k = "move up";
        alt-shift-l = "move right";

        alt-shift-n = "workspace --wrap-around next";
        alt-shift-p = "workspace --wrap-around prev";

        # Move window to workspace
        alt-shift-1 = [
          "move-node-to-workspace 1"
          "workspace 1"
        ];
        alt-shift-2 = [
          "move-node-to-workspace 2"
          "workspace 2"
        ];
        alt-shift-3 = [
          "move-node-to-workspace 3"
          "workspace 3"
        ];
        alt-shift-4 = [
          "move-node-to-workspace 4"
          "workspace 4"
        ];
        alt-shift-5 = [
          "move-node-to-workspace 5"
          "workspace 5"
        ];
        alt-shift-6 = [
          "move-node-to-workspace 6"
          "workspace 6"
        ];
        alt-shift-7 = [
          "move-node-to-workspace 7"
          "workspace 7"
        ];
        alt-shift-8 = [
          "move-node-to-workspace 8"
          "workspace 8"
        ];
        alt-shift-9 = [
          "move-node-to-workspace 9"
          "workspace 9"
        ];
        alt-shift-0 = [
          "move-node-to-workspace 10"
          "workspace 10"
        ];

        # Layout / state
        alt-tab = "workspace-back-and-forth";
        alt-comma = "layout accordion tiles";
        alt-f = "layout floating tiling";
        alt-q = "close";
      };

      "on-window-detected" = [
        {
          "if".app-id = "com.microsoft.edgemac";
          run = [
            "move-node-to-workspace 1"
          ];
        }
        {
          "if".app-id = "com.mitchellh.ghostty";
          run = [
            "move-node-to-workspace 2"
          ];
        }
        {
          "if".app-id = "md.obsidian";
          run = [
            "move-node-to-workspace 4"
          ];
        }
        {
          "if".app-id = "com.spotify.client";
          run = [
            "move-node-to-workspace 5"
          ];
        }
        {
          "if".app-id = "com.apple.finder";
          run = [
            "move-node-to-workspace 6"
          ];
        }
        {
          run = "move-node-to-workspace 3";
        }
      ];
    };
  };
}
