{
  programs.aerospace = {
    enable = true;

    settings = {
      "start-at-login" = true;
      "after-startup-command" = [ ];

      "enable-normalization-flatten-containers" = true;
      "enable-normalization-opposite-orientation-for-nested-containers" = true;

      "default-root-container-layout" = "tiles";
      "default-root-container-orientation" = "auto";

      "on-focused-monitor-changed" = [ "move-mouse monitor-lazy-center" ];

      "automatically-unhide-macos-hidden-apps" = false;

      "persistent-workspaces" = ["1";  "2"; "3"; "4" ; "5"; "6"; "7"];


      "key-mapping" = {
        preset = "qwerty";
      };

      gaps = {
        inner.horizontal = 1;
        inner.vertical = 4;
        outer.left = 4;
        outer.bottom = 4;
        outer.top = 4;
        outer.right = 4;
      };

      mode.main.binding = {
        # Launcher (Hyprland: SUPER+SPACE -> rofi)
        alt-space = "exec-and-forget open -a Raycast";

        # Apps (Hyprland: ALT+number launchers)
        alt-1 = "exec-and-forget open -a \"Microsoft Edge\"";
        alt-2 = "exec-and-forget open -a Ghostty";
        alt-3 = "exec-and-forget open -a \"Visual Studio Code\"";
        alt-4 = "exec-and-forget open -a Obsidian";
        alt-5 = "exec-and-forget open -a Spotify";
        alt-6 = "exec-and-forget open $HOME";

        # Focus
        alt-h = "focus left";
        alt-j = "focus down";
        alt-k = "focus up";
        alt-l = "focus right";

        # Move window
        alt-shift-h = "move left";
        alt-shift-j = "move down";
        alt-shift-k = "move up";
        alt-shift-l = "move right";

        # Workspace switching (separated from alt-1..6 launchers)
        alt-cmd-1 = "workspace 1";
        alt-cmd-2 = "workspace 2";
        alt-cmd-3 = "workspace 3";
        alt-cmd-4 = "workspace 4";
        alt-cmd-5 = "workspace 5";
        alt-cmd-6 = "workspace 6";
        alt-cmd-7 = "workspace 7";
        alt-cmd-8 = "workspace 8";
        alt-cmd-9 = "workspace 9";
        alt-cmd-0 = "workspace 10";

        # Move window to workspace
        alt-cmd-shift-1 = "move-node-to-workspace 1";
        alt-cmd-shift-2 = "move-node-to-workspace 2";
        alt-cmd-shift-3 = "move-node-to-workspace 3";
        alt-cmd-shift-4 = "move-node-to-workspace 4";
        alt-cmd-shift-5 = "move-node-to-workspace 5";
        alt-cmd-shift-6 = "move-node-to-workspace 6";
        alt-cmd-shift-7 = "move-node-to-workspace 7";
        alt-cmd-shift-8 = "move-node-to-workspace 8";
        alt-cmd-shift-9 = "move-node-to-workspace 9";
        alt-cmd-shift-0 = "move-node-to-workspace 10";

        # Layout / state
        alt-f = "fullscreen";
        alt-shift-space = "layout floating tiling";
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
      ];
    };
  };
}
