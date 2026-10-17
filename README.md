# Nix setup

Use your existing local copy of this repository.

- [Desktop](docs/desktop.md)
- [Server](docs/server.md)
- [Dependency updates and server deployment](docs/deployment.md)
- [MacBook](docs/macbook.md)
- [Docker containers](docs/docker.md)
- [Media stack](docs/media.md)
- [Hermes and agent tools](docs/hermes.md)

Each guide covers installation and rebuilding. The configurations use account `felix`.
Replace `/path/to/nixos` with your repository directory; a fresh NixOS install
below leaves it at `/etc/nixos`.

## Files

```text
.
├── flake.nix       # Host configurations and dependencies
├── flake.lock      # Pinned dependency versions
├── hosts/          # Settings and hardware for each machine
├── modules/        # Shared NixOS and macOS configuration
│   └── server/     # Docker, storage, secrets, and container definitions
├── home/           # User apps, shell, desktop, and agent tools
├── secrets/server/ # Encrypted credentials and public-key recipients
├── docs/           # Setup and usage guides
├── wallpapers/     # Desktop wallpapers
└── README.md       # Start here
```
