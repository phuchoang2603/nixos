{ pkgs, ... }:

{
  programs = {
    # kitty = {
    #   enable = true;
    #   shellIntegration.enableZshIntegration = true;
    #   settings = {
    #     background_opacity = lib.mkForce 0.9;
    #     confirm_os_window_close = "0";
    #     cursor_trail = 2;
    #     hide_window_decorations = "yes";
    #     window_padding_width = 10;
    #   };
    #   keybindings = {
    #     "cmd+enter" = "no_op";
    #   };
    # };

    ghostty = {
      enable = true;
      package = if pkgs.stdenv.hostPlatform.isDarwin then pkgs.ghostty-bin else pkgs.ghostty;
      settings = {
        # Font configuration
        font-family = "CaskaydiaMono Nerd Font";
        font-size = 15;

        # Window settings
        confirm-close-surface = false;
        window-decoration = false;
        window-padding-x = 10;
        window-padding-y = 10;
        background-opacity = 0.9;

        # Keybind
        keybind = [
          "ctrl+enter=unbind"
        ];
      };
    };
  };
}
