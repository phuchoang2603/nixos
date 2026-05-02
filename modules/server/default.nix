{
  imports = [
    ./base.nix
    ./nvidia.nix
    ./docker.nix
    ./nfs.nix
    ./ssh.nix
  ];

  # Enable flakes
  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    # Auto-optimize store
    auto-optimise-store = true;
  };

  # Garbage collection
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };
}
