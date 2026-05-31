{ pkgs, ... }:

{
  programs.yazi = {
    enable = true;
    enableZshIntegration = true;
    shellWrapperName = "y";

    plugins = {
      clipboard = pkgs.yaziPlugins.clipboard;
    };

    keymap = {
      mgr.prepend_keymap = [
        {
          on = [
            "g"
            "r"
          ];
          run = ''shell -- ya emit cd "$(git rev-parse --show-toplevel)"'';
          desc = "Go to git repository root";
        }
        {
          on = [
            "<C-c>"
          ];
          run = [
            "yank"
            "plugin clipboard -- --action=copy"
          ];
          desc = "Copy yanked files to the system clipboard";
        }
        {
          on = [
            "<C-v>"
          ];
          run = [
            "plugin clipboard -- --action=paste"
          ];
          desc = "Paste files from the system clipboard into the current directory";
        }
      ];
    };

    settings = {
      mgr = {
        ratio = [
          1
          4
          4
        ];
        sort_by = "natural";
        linemode = "none";
        show_hidden = true;
        show_symlink = true;
        scrolloff = 5;
        mouse_events = [
          "click"
          "scroll"
          "drag"
        ];
      };

      preview = {
        wrap = "yes";
        tab_size = 2;
        image_filter = "triangle";
        image_quality = 50;
      };

    };
  };
}
