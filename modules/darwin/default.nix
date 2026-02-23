{ pkgs, lib, ... }:

{
  imports = [
    ./system.nix
  ];

  # Nix settings
  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    auto-optimise-store = true;
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
