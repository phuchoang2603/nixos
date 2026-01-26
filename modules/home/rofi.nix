{ pkgs, lib, config, ... }:

{
  programs.rofi = {
    enable = true;
    package = pkgs.rofi;
    theme = let
      # Use Stylix colors - these will be automatically generated
      inherit (config.lib.stylix) colors;
    in ''
      * {
          border-colour:               ${colors.base0A};
          handle-colour:               ${colors.base0A};
          background-colour:           ${colors.base00};
          foreground-colour:           ${colors.base05};
          alternate-background:        ${colors.base01};
          normal-background:           ${colors.base00};
          normal-foreground:           ${colors.base05};
          urgent-background:           ${colors.base08};
          urgent-foreground:           ${colors.base00};
          active-background:           ${colors.base0B};
          active-foreground:           ${colors.base00};
          selected-normal-background:  ${colors.base0A};
          selected-normal-foreground:  ${colors.base00};
          selected-urgent-background:  ${colors.base0B};
          selected-urgent-foreground:  ${colors.base00};
          selected-active-background:  ${colors.base08};
          selected-active-foreground:  ${colors.base00};
          alternate-normal-background: ${colors.base00};
          alternate-normal-foreground: ${colors.base05};
          alternate-urgent-background: ${colors.base08};
          alternate-urgent-foreground: ${colors.base00};
          alternate-active-background: ${colors.base0B};
          alternate-active-foreground: ${colors.base00};
      }

      window {
          transparency:                "real";
          location:                    center;
          anchor:                      center;
          fullscreen:                  false;
          x-offset:                    0px;
          y-offset:                    0px;
          enabled:                     true;
          margin:                      0px;
          padding:                     0px;
          border:                      1px solid;
          border-radius:               12px;
          border-color:                ${colors.base0A};
          cursor:                      "default";
          background-color:            ${colors.base00};
      }

      mainbox {
          enabled:                     true;
          spacing:                     10px;
          margin:                      0px;
          padding:                     20px;
          border:                      0px solid;
          border-radius:               4px;
          border-color:                ${colors.base0A};
          background-color:            transparent;
          children:                    [ "inputbar", "message", "listview" ];
      }

      inputbar {
          enabled:                     true;
          spacing:                     10px;
          margin:                      0px;
          padding:                     10px;
          border:                      0px solid;
          border-radius:               4px;
          border-color:                ${colors.base0A};
          background-color:            ${colors.base01};
          text-color:                  ${colors.base05};
          children:                    [ "prompt", "textbox-prompt-colon", "entry" ];
      }

      prompt {
          enabled:                     true;
          background-color:            inherit;
          text-color:                  inherit;
      }

      textbox-prompt-colon {
          enabled:                     true;
          expand:                      false;
          str:                         "::";
          background-color:            inherit;
          text-color:                  inherit;
      }

      entry {
          enabled:                     true;
          background-color:            inherit;
          text-color:                  inherit;
          cursor:                      text;
          placeholder:                 "Search...";
          placeholder-color:           inherit;
      }

      listview {
          enabled:                     true;
          columns:                     1;
          lines:                       6;
          cycle:                       true;
          dynamic:                     true;
          scrollbar:                   true;
          layout:                      vertical;
          reverse:                     false;
          fixed-height:                true;
          fixed-columns:               true;
          spacing:                     10px;
          margin:                      0px;
          padding:                     0px;
          border:                      0px solid;
          border-radius:               4px;
          border-color:                ${colors.base0A};
          background-color:            transparent;
          text-color:                  ${colors.base05};
          cursor:                      "default";
      }

      scrollbar {
          handle-width:                5px ;
          handle-color:                ${colors.base0A};
          border-radius:               4px;
          background-color:            ${colors.base01};
      }

      element {
          enabled:                     true;
          spacing:                     10px;
          margin:                      0px;
          padding:                     10px;
          border:                      0px solid;
          border-radius:               4px;
          border-color:                ${colors.base0A};
          background-color:            transparent;
          text-color:                  ${colors.base05};
          cursor:                      pointer;
      }

      element normal.normal {
          background-color:            ${colors.base00};
          text-color:                  ${colors.base05};
      }

      element normal.urgent {
          background-color:            ${colors.base08};
          text-color:                  ${colors.base00};
      }

      element normal.active {
          background-color:            ${colors.base0B};
          text-color:                  ${colors.base00};
      }

      element selected.normal {
          background-color:            ${colors.base0A};
          text-color:                  ${colors.base00};
      }

      element selected.urgent {
          background-color:            ${colors.base0B};
          text-color:                  ${colors.base00};
      }

      element selected.active {
          background-color:            ${colors.base08};
          text-color:                  ${colors.base00};
      }

      element alternate.normal {
          background-color:            ${colors.base00};
          text-color:                  ${colors.base05};
      }

      element alternate.urgent {
          background-color:            ${colors.base08};
          text-color:                  ${colors.base00};
      }

      element alternate.active {
          background-color:            ${colors.base0B};
          text-color:                  ${colors.base00};
      }

      element-icon {
          background-color:            transparent;
          text-color:                  inherit;
          size:                        24px;
          cursor:                      inherit;
      }

      element-text {
          background-color:            transparent;
          text-color:                  inherit;
          highlight:                   inherit;
          cursor:                      inherit;
          vertical-align:              0.5;
          horizontal-align:            0.0;
      }

      mode-switcher{
          enabled:                     true;
          spacing:                     10px;
          margin:                      0px;
          padding:                     0px;
          border:                      0px solid;
          border-radius:               4px;
          border-color:                ${colors.base0A};
          background-color:            transparent;
          text-color:                  ${colors.base05};
      }

      button {
          padding:                     10px;
          border:                      0px solid;
          border-radius:               4px;
          border-color:                ${colors.base0A};
          background-color:            ${colors.base01};
          text-color:                  inherit;
          cursor:                      pointer;
      }

      button selected {
          background-color:            ${colors.base0A};
          text-color:                  ${colors.base00};
      }

      message {
          enabled:                     true;
          margin:                      0px;
          padding:                     0px;
          border:                      0px solid;
          border-radius:               0px 0px 0px 0px;
          border-color:                ${colors.base0A};
          background-color:            transparent;
          text-color:                  ${colors.base05};
      }

      textbox {
          padding:                     10px;
          border:                      0px solid;
          border-radius:               4px;
          border-color:                ${colors.base0A};
          background-color:            ${colors.base01};
          text-color:                  ${colors.base05};
          vertical-align:              0.5;
          horizontal-align:            0.0;
          highlight:                   none;
          placeholder-color:           ${colors.base05};
          blink:                       true;
          markup:                      true;
      }

      error-message {
          padding:                     10px;
          border:                      2px solid;
          border-radius:               4px;
          border-color:                ${colors.base0A};
          background-color:            ${colors.base00};
          text-color:                  ${colors.base05};
      }
    '';
  };
}