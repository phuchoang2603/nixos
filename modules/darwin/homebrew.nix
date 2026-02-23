{ ... }:

# Homebrew configuration for macOS
# Manages apps not available in nixpkgs or better installed via Homebrew

{
  # Enable Homebrew
  homebrew = {
    enable = true;

    # Automatically update Homebrew
    onActivation = {
      autoUpdate = true;
      cleanup = "zap";
      upgrade = true;
    };

    caskArgs.no_quarantine = true;
    global.brewfile = true;

    # Taps
    taps = [ ];

    # CLI packages
    brews = [
      "mas"
      "docker"
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
