{ pkgs, lib, ... }:

{
  imports = [
    ./packages.nix
    ./shell.nix
    ./git.nix
    ./starship.nix
    ./programs.nix
    ./tmux.nix
    ./yazi.nix
    ./ghostty.nix
    ./spicetify.nix
    ./dotfiles.nix
  ];

  # Home Manager configuration
  home = {
    stateVersion = "25.11";
  };

  # Let Home Manager manage itself
  programs.home-manager.enable = true;

  # Enable XDG base directories
  xdg.enable = true;
}
