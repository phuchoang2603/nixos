{ lib, ... }:

{
  programs.kitty = {
    enable = true;
    shellIntegration.enableZshIntegration = true;
    settings = {
      background_opacity = lib.mkForce 0.9;
      confirm_os_window_close = "0";
      cursor_trail = 2;
      hide_window_decorations = "yes";
      window_padding_width = 10;
    };
  };
}
