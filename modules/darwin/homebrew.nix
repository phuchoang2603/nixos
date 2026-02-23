{
  pkgs,
  lib,
  config,
  ...
}:

# Homebrew configuration for macOS
# Manages apps not available in nixpkgs or better installed via Homebrew

{
  # Enable Homebrew
  homebrew = {
    enable = true;

    # Automatically update Homebrew
    onActivation = {
      autoUpdate = true;
      cleanup = "zap"; # Remove formulae not in the list
      upgrade = true;
    };

    # Taps
    taps = [ ];

    # CLI packages (prefer nixpkgs when possible)
    brews = [
      # Add macOS-specific brews here
    ];

    # GUI applications
    casks = [
      "microsoft-edge"
      "visual-studio-code"
      "datagrip"
      "obsidian"
    ];

    # Mac App Store apps (requires mas CLI)
    masApps = {
      # "App Name" = app-id;
    };
  };
}
