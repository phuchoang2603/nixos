{ pkgs, lib, ... }:

{
  imports = [
    ./system.nix
    ./homebrew.nix
  ];

  # Nix settings
  nix = {
    settings = {
      experimental-features = "nix-command flakes";
    };
    optimise.automatic = true;
  };

  # Garbage collection
  nix.gc = {
    automatic = true;
    interval = {
      Hour = 0;
      Minute = 0;
      Weekday = 7;
    };
    options = "--delete-older-than 7d";
  };
}
