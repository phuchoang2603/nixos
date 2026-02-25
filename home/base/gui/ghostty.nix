{
  pkgs,
  ...
}:

{
  programs.ghostty = {
    enable = true;

    # Logic to switch package based on OS
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
}
