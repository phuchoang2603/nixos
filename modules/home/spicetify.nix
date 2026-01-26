{ pkgs, lib, config, inputs, ... }:

let
  spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};
in
{
  imports = [ inputs.spicetify-nix.homeManagerModules.default ];

  programs.spicetify = {
    enable = true;

    theme = spicePkgs.themes.sleek;
    colorScheme = "UltraBlack";

    # Enable useful extensions
    enabledExtensions = with spicePkgs.extensions; [
      adblockify
      hidePodcasts
      history
    ];
  };
}
