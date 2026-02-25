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
    taps = [
    ];

    # CLI packages
    brews = [
      "mas"
      "colima"
      "docker"
      "docker-compose"
      "docker-credential-helper"
    ];

    # GUI applications
    casks = [
      "microsoft-edge"
      "raycast"
      "visual-studio-code"
      "datagrip"
      "obsidian"
      "skim"
      "bettertouchtool"
    ];

    # Mac App Store apps (requires mas CLI)
    masApps = {
      "Microsoft OneNote" = 784801555;
      "Microsoft OneDrive" = 823766827;
      "Microsoft Word" = 462054704;
      "Microsoft Excel" = 462058435;
      "Microsoft PowerPoint" = 462062816;
    };
  };
}
