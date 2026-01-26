{ pkgs, config, ... }:

{
  programs.rofi = {
    enable = true;
    package = pkgs.rofi;
    
    # Configuration settings
    modes = [ "window" "drun" "run" "ssh" "keys" "filebrowser" "combi" ];
    cycle = true;
    font = "CaskaydiaMono Nerd Font 10";
    terminal = "ghostty";
    location = "center";
    xoffset = 0;
    yoffset = 0;
    
    # Mode display names
    extraConfig = {
      display-window = "Windows";
      display-run = "Run";
      display-ssh = "SSH";
      display-drun = "Apps";
      display-combi = "Combi";
      display-keys = "Keys";
      display-filebrowser = "Files";
      
      # Display formatting
      drun-display-format = "{name} [<span weight='light' size='small'><i>({generic})</i></span>]";
      window-format = "{w} · {c} · {t}";
      
      # Combi settings
      combi-modes = [ "window" "drun" "ssh" ];
      combi-hide-mode-prefix = false;
      
      # General settings
      case-sensitive = false;
      filter = "";
      scroll-method = 0;
      normalize-match = true;
      show-icons = true;
      icon-theme = "Papirus";
      steal-focus = true;
      sort = false;
      threads = 0;
      click-to-exit = true;
      dpi = 1;
      
      # Matching settings
      matching = "normal";
      tokenize = true;
      
      # SSH settings
      ssh-client = "ssh";
      ssh-command = "ghostty -e ssh {host}";
      parse-hosts = true;
      parse-known-hosts = true;
      
      # Run settings
      run-command = "{cmd}";
      run-list-command = "";
      run-shell-command = "{terminal} -e {cmd}";
      
      # History and sorting
      disable-history = false;
      sorting-method = "normal";
      max-history-size = 25;
      
      # Mode-specific configurations
      "run.drun" = {
        fallback-icon = "application-x-addon";
      };
      "filebrowser" = {
        directories-first = true;
        sorting-method = "name";
      };
      "timeout" = {
        action = "kb-cancel";
        delay = 0;
      };
    };
    
    # Theme configuration with stylix colors
    theme = let
      inherit (config.lib.stylix) colors;
    in {
      # Color variables
      "*" = {
        border-colour = "#${colors.base0A}";
        handle-colour = "#${colors.base0A}";
        background-colour = "#${colors.base00}";
        foreground-colour = "#${colors.base05}";
        alternate-background = "#${colors.base01}";
        normal-background = "#${colors.base00}";
        normal-foreground = "#${colors.base05}";
        urgent-background = "#${colors.base08}";
        urgent-foreground = "#${colors.base00}";
        active-background = "#${colors.base0B}";
        active-foreground = "#${colors.base00}";
        selected-normal-background = "#${colors.base0A}";
        selected-normal-foreground = "#${colors.base00}";
        selected-urgent-background = "#${colors.base0B}";
        selected-urgent-foreground = "#${colors.base00}";
        selected-active-background = "#${colors.base08}";
        selected-active-foreground = "#${colors.base00}";
        alternate-normal-background = "#${colors.base00}";
        alternate-normal-foreground = "#${colors.base05}";
        alternate-urgent-background = "#${colors.base08}";
        alternate-urgent-foreground = "#${colors.base00}";
        alternate-active-background = "#${colors.base0B}";
        alternate-active-foreground = "#${colors.base00}";
      };

      # Main window
      "window" = {
        transparency = "real";
        location = "center";
        anchor = "center";
        fullscreen = false;
        enabled = true;
        margin = "0px";
        padding = "0px";
        border = "1px solid";
        border-radius = "12px";
        border-color = "#${colors.base0A}";
        cursor = "default";
        background-color = "#${colors.base00}";
      };

      # Main container
      "mainbox" = {
        enabled = true;
        spacing = "10px";
        margin = "0px";
        padding = "20px";
        border = "0px solid";
        border-radius = "4px";
        border-color = "#${colors.base0A}";
        background-color = "transparent";
        children = [ "inputbar" "message" "listview" ];
      };

      # Input bar
      "inputbar" = {
        enabled = true;
        spacing = "10px";
        margin = "0px";
        padding = "10px";
        border = "0px solid";
        border-radius = "4px";
        border-color = "#${colors.base0A}";
        background-color = "#${colors.base01}";
        text-color = "#${colors.base05}";
        children = [ "prompt" "textbox-prompt-colon" "entry" ];
      };

      # Prompt elements
      "prompt" = {
        enabled = true;
        background-color = "inherit";
        text-color = "inherit";
      };

      "textbox-prompt-colon" = {
        enabled = true;
        expand = false;
        str = "::";
        background-color = "inherit";
        text-color = "inherit";
      };

      "entry" = {
        enabled = true;
        background-color = "inherit";
        text-color = "inherit";
        cursor = "text";
        placeholder = "Search...";
        placeholder-color = "inherit";
      };

      # List view
      "listview" = {
        enabled = true;
        columns = 1;
        lines = 6;
        cycle = true;
        dynamic = true;
        scrollbar = true;
        layout = "vertical";
        reverse = false;
        fixed-height = true;
        fixed-columns = true;
        spacing = "10px";
        margin = "0px";
        padding = "0px";
        border = "0px solid";
        border-radius = "4px";
        border-color = "#${colors.base0A}";
        background-color = "transparent";
        text-color = "#${colors.base05}";
        cursor = "default";
      };

      # Scrollbar
      "scrollbar" = {
        handle-width = "5px";
        handle-color = "#${colors.base0A}";
        border-radius = "4px";
        background-color = "#${colors.base01}";
      };

      # Elements
      "element" = {
        enabled = true;
        spacing = "10px";
        margin = "0px";
        padding = "10px";
        border = "0px solid";
        border-radius = "4px";
        border-color = "#${colors.base0A}";
        background-color = "transparent";
        text-color = "#${colors.base05}";
        cursor = "pointer";
      };

      # Element states
      "element normal.normal" = {
        background-color = "#${colors.base00}";
        text-color = "#${colors.base05}";
      };

      "element normal.urgent" = {
        background-color = "#${colors.base08}";
        text-color = "#${colors.base00}";
      };

      "element normal.active" = {
        background-color = "#${colors.base0B}";
        text-color = "#${colors.base00}";
      };

      "element selected.normal" = {
        background-color = "#${colors.base0A}";
        text-color = "#${colors.base00}";
      };

      "element selected.urgent" = {
        background-color = "#${colors.base0B}";
        text-color = "#${colors.base00}";
      };

      "element selected.active" = {
        background-color = "#${colors.base08}";
        text-color = "#${colors.base00}";
      };

      "element alternate.normal" = {
        background-color = "#${colors.base00}";
        text-color = "#${colors.base05}";
      };

      "element alternate.urgent" = {
        background-color = "#${colors.base08}";
        text-color = "#${colors.base00}";
      };

      "element alternate.active" = {
        background-color = "#${colors.base0B}";
        text-color = "#${colors.base00}";
      };

      # Element components
      "element-icon" = {
        background-color = "transparent";
        text-color = "inherit";
        size = "24px";
        cursor = "inherit";
      };

      "element-text" = {
        background-color = "transparent";
        text-color = "inherit";
        highlight = "inherit";
        cursor = "inherit";
        vertical-align = 0.5;
        horizontal-align = 0.0;
      };

      # Mode switcher
      "mode-switcher" = {
        enabled = true;
        spacing = "10px";
        margin = "0px";
        padding = "0px";
        border = "0px solid";
        border-radius = "4px";
        border-color = "#${colors.base0A}";
        background-color = "transparent";
        text-color = "#${colors.base05}";
      };

      # Buttons
      "button" = {
        padding = "10px";
        border = "0px solid";
        border-radius = "4px";
        border-color = "#${colors.base0A}";
        background-color = "#${colors.base01}";
        text-color = "inherit";
        cursor = "pointer";
      };

      "button selected" = {
        background-color = "#${colors.base0A}";
        text-color = "#${colors.base00}";
      };

      # Messages
      "message" = {
        enabled = true;
        margin = "0px";
        padding = "0px";
        border = "0px solid";
        border-radius = "0px 0px 0px 0px";
        border-color = "#${colors.base0A}";
        background-color = "transparent";
        text-color = "#${colors.base05}";
      };

      "textbox" = {
        padding = "10px";
        border = "0px solid";
        border-radius = "4px";
        border-color = "#${colors.base0A}";
        background-color = "#${colors.base01}";
        text-color = "#${colors.base05}";
        vertical-align = 0.5;
        horizontal-align = 0.0;
        highlight = "none";
        placeholder-color = "#${colors.base05}";
        blink = true;
        markup = true;
      };

      "error-message" = {
        padding = "10px";
        border = "2px solid";
        border-radius = "4px";
        border-color = "#${colors.base0A}";
        background-color = "#${colors.base00}";
        text-color = "#${colors.base05}";
      };
    };
  };
}