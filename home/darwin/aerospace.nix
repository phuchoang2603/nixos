{
  programs.aerospace = {
    enable = true;
    launchd.enable = true;

    settings = {
      "start-at-login" = true;
      "after-startup-command" = [ ];

      "enable-normalization-flatten-containers" = true;
      "enable-normalization-opposite-orientation-for-nested-containers" = true;

      "default-root-container-layout" = "tiles";
      "default-root-container-orientation" = "auto";

      "on-focused-monitor-changed" = [ "move-mouse monitor-lazy-center" ];
      "on-focus-changed" = [ "move-mouse window-lazy-center" ];

      "automatically-unhide-macos-hidden-apps" = false;

      "key-mapping" = {
        preset = "qwerty";
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
        # Launcher
        cmd-space = "exec-and-forget open -a Raycast";

        # Apps
        alt-1 = "exec-and-forget open -a \"Microsoft Edge\"";
        alt-2 = "exec-and-forget open -a Ghostty";
        alt-3 = "exec-and-forget open -a \"Visual Studio Code\"";
        alt-4 = "exec-and-forget open -a Obsidian";
        alt-5 = "exec-and-forget open -a Spotify";
        alt-6 = "exec-and-forget open $HOME";

        # Focus
        cmd-h = "focus left";
        cmd-j = "focus down";
        cmd-k = "focus up";
        cmd-l = "focus right";

        # Move window
        cmd-shift-h = "move left";
        cmd-shift-j = "move down";
        cmd-shift-k = "move up";
        cmd-shift-l = "move right";

        # Workspace switching
        cmd-1 = "workspace 1";
        cmd-2 = "workspace 2";
        cmd-3 = "workspace 3";
        cmd-4 = "workspace 4";
        cmd-5 = "workspace 5";
        cmd-6 = "workspace 6";

        cmd-shift-n = "workspace --wrap-around next";
        cmd-shift-p = "workspace --wrap-around prev";

        # Move window to workspace
        cmd-shift-1 = "move-node-to-workspace 1";
        cmd-shift-2 = "move-node-to-workspace 2";
        cmd-shift-3 = "move-node-to-workspace 3";
        cmd-shift-4 = "move-node-to-workspace 4";
        cmd-shift-5 = "move-node-to-workspace 5";
        cmd-shift-6 = "move-node-to-workspace 6";

        # Move window to monitor
        cmd-shift-left = "move-node-to-monitor left";
        cmd-shift-right = "move-node-to-monitor right";

        # Layout / state
        cmd-w = "close";
        cmd-tab = "workspace-back-and-forth";
        f11 = "fullscreen";
        cmd-f = "layout floating tiling";
      };

      "on-window-detected" = [
        {
          "if".app-id = "com.microsoft.edgemac";
          run = "move-node-to-workspace 1";
        }
        {
          "if".app-id = "com.mitchellh.ghostty";
          run = "move-node-to-workspace 2";
        }
        {
          "if".app-id = "com.microsoft.VSCode";
          run = "move-node-to-workspace 3";
        }
        {
          "if".app-id = "md.obsidian";
          run = "move-node-to-workspace 4";
        }
        {
          "if".app-id = "com.spotify.client";
          run = "move-node-to-workspace 5";
        }
        {
          "if".app-id = "com.apple.finder";
          run = "move-node-to-workspace 6";
        }
      ];
    };
  };
}
