{ pkgs, ... }:

{
  # Fcitx5 input method with Vietnamese support
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5 = {
      waylandFrontend = true;
      addons = with pkgs; [
        qt6Packages.fcitx5-unikey # Vietnamese input
        fcitx5-gtk # GTK integration
        qt6Packages.fcitx5-configtool # Configuration tool
      ];
    };
  };

  # Environment variables for input method
  home.sessionVariables = {
    # GTK_IM_MODULE = "fcitx";
    QT_IM_MODULE = "fcitx";
    XMODIFIERS = "@im=fcitx";
    SDL_IM_MODULE = "fcitx";
    GLFW_IM_MODULE = "ibus"; # For some apps that don't support fcitx directly
  };
}
