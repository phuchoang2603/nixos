{ ... }:

{
  imports = [
    ./packages.nix
    ./shell.nix
    ./tmux.nix
    ./git.nix
    ./yazi.nix
    ./opencode.nix
    ./neovim.nix
    ./direnv.nix
    # GUI apps
    ./ghostty.nix
    ./theming.nix
    ./spicetify.nix
  ];

  # Home Manager configuration
  home.stateVersion = "25.11";

  # Let Home Manager manage itself
  programs.home-manager.enable = true;

  # Enable XDG base directories
  xdg.enable = true;
}
