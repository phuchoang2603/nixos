{
  pkgs,
  lib,
  config,
  ...
}:

# macOS system configuration placeholder
# TODO: Expand this when setting up macOS

{
  # System settings
  system = {
    # Used for backwards compatibility
    stateVersion = 4;

    defaults = {
      # Dock settings
      dock = {
        autohide = true;
        mru-spaces = false;
        show-recents = false;
      };

      # Finder settings
      finder = {
        AppleShowAllExtensions = true;
        FXEnableExtensionChangeWarning = false;
        _FXShowPosixPathInTitle = true;
      };

      # Global settings
      NSGlobalDomain = {
        AppleShowAllExtensions = true;
        InitialKeyRepeat = 15;
        KeyRepeat = 2;
      };
    };
  };

  # Enable Touch ID for sudo
  security.pam.enableSudoTouchIdAuth = true;

  # Nix settings
  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    auto-optimise-store = true;
  };

  # Fonts
  fonts.packages = with pkgs; [
    (nerdfonts.override {
      fonts = [
        "CascadiaCode"
        "JetBrainsMono"
      ];
    })
    inter
  ];
}
