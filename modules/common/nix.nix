{ lib, ... }:

let
  cache = builtins.fromJSON (builtins.readFile ./cachix.json);
in
{
  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    auto-optimise-store = true;
  }
  // lib.optionalAttrs (cache.publicKey != null) {
    extra-substituters = [ "https://${cache.name}.cachix.org" ];
    extra-trusted-public-keys = [ cache.publicKey ];
  };

  nix.gc = {
    automatic = true;
    dates = "daily";
    options = "--delete-older-than 7d";
  };
}
