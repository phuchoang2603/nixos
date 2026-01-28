{ ... }:

{
  # Home Manager configuration
  home.stateVersion = "25.11";

  # Let Home Manager manage itself
  programs.home-manager.enable = true;

  # Enable XDG base directories
  xdg.enable = true;
}
