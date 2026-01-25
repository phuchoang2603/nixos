{ pkgs, lib, config, inputs, ... }:

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
      adblockify
      hidePodcasts
      history
    ];
  };
}
