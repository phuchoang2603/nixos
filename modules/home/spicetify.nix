{ pkgs, lib, config, inputs, ... }:

# Spicetify configuration using spicetify-nix
# The color.ini file is managed by pywal and symlinked via dotfiles.nix
# spicetify-nix handles the Spotify installation and theming structure

let
  spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.system};
in
{
  imports = [ inputs.spicetify-nix.homeManagerModules.default ];

  programs.spicetify = {
    enable = true;

    # Use the Sleek theme - pywal will write colors to color.ini
    theme = spicePkgs.themes.sleek;

    # Enable useful extensions
    enabledExtensions = with spicePkgs.extensions; [
      adblock
      hidePodcasts
      shuffle
    ];
  };
}
