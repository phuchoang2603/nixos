{ ... }:

# Homebrew configuration for macOS
# Manages apps not available in nixpkgs or better installed via Homebrew

{
  # Enable Homebrew
  homebrew = {
    enable = true;
    enableZshIntegration = true;

    # Automatically update Homebrew
    onActivation = {
      cleanup = "zap";
      autoUpdate = true;
      upgrade = true;
    };

    global.brewfile = true;

    # CLI packages
    brews = [
      "colima"
      "docker"
      "docker-compose"
      "docker-buildx"
      "docker-credential-helper"
    ];

    # GUI applications
    casks = [
      "onedrive"
      "microsoft-edge"
      "microsoft-teams"
      "microsoft-onenote"
      "microsoft-word"
      "microsoft-excel"
      "microsoft-powerpoint"
      "raycast"
      "visual-studio-code"
      "cursor"
      "datagrip"
      "obsidian"
      "zalo"
      "karabiner-elements"
      "bettertouchtool"
      "yaak"
      "jdownloader"
      "vlc"
    ];
  };
}
