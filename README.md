# Nix Config (NixOS + macOS)

Flake-based configuration for three hosts:

| Host            | Platform | Purpose           | Home Manager                       |
| --------------- | -------- | ----------------- | ---------------------------------- |
| `nixos-desktop` | NixOS    | Hyprland desktop  | CLI + GUI (Stylix, Hyprland stack) |
| `nixos-server`  | NixOS    | Docker/NFS server | CLI only                           |
| `macbook`       | macOS    | nix-darwin laptop | CLI + GUI (Stylix, AeroSpace)      |

## Layout

```
flake.nix                 # inputs + nixosConfigurations + darwinConfigurations
hosts/
  nixos-desktop/          # desktop system + monitor overrides
  nixos-server/           # server system + hardware config
  macbook/                # macOS system entrypoint
home/
  base/cli/               # shared CLI tools, shell, neovim, git, tmux
  base/gui/               # shared GUI (kitty, stylix theming)
  linux/                  # desktop Wayland stack (Hyprland, rofi, waybar, ...)
  darwin/                 # macOS home (AeroSpace, Karabiner)
  server/                 # server home profile (CLI only)
modules/
  common/                 # shared boot, locale, nix settings (NixOS)
  nixos/                  # desktop system modules
  server/                 # docker, nfs, ssh, containers/
  darwin/                 # nix-darwin system modules
```

## Usage

### NixOS desktop

```bash
nh os switch .#nixos-desktop
# or
sudo nixos-rebuild switch --flake .#nixos-desktop
```

### NixOS server

```bash
nh os switch .#nixos-server
# or
sudo nixos-rebuild switch --flake .#nixos-server
```

Remote apply:

```bash
nh os switch .#nixos-server \
  --build-host felix@nixos-server \
  --target-host felix@nixos-server
```

`nh os switch .` picks the configuration matching the current hostname.

### macOS

```bash
darwin-rebuild switch --flake .#macbook
```

## Fresh install (NixOS desktop)

1. Partition the disk with cfdisk (GPT, 512M EFI + ext4 root).
2. Format and mount:

```bash
sudo mkfs.fat -F 32 -n boot /dev/nvme0n1p1
sudo mkfs.ext4 -L nixos /dev/nvme0n1p2
sudo mount /dev/disk/by-label/nixos /mnt
sudo mkdir -p /mnt/boot
sudo mount /dev/disk/by-label/boot /mnt/boot
```

1. Clone and install:

```bash
sudo git clone https://github.com/phuchoang2603/nixos.git /mnt/etc/nixos
cd /mnt/etc/nixos
sudo nixos-generate-config --root /mnt --show-hardware-config | sudo tee hosts/nixos-desktop/hardware-configuration.nix
sudo nixos-install --flake .#nixos-desktop
```

For a server install, use `nixos-server` and `hosts/nixos-server/hardware-configuration.nix`.

### Docker containers

Containers are declared in Nix under `modules/server/containers/` using
`virtualisation.oci-containers`. Services share the Docker `proxy` network, with
Traefik routing configured services over ports 80/443. Application data and
databases live in one directory per application under `/mnt/storage/container`,
an ext4 filesystem on the TrueNAS `storage/container` zvol connected directly
through iSCSI. Only media uses NFS, at `/mnt/storage/media`. Docker images and
the Nix store remain on the host disk. Each container requires the mounts used
by its bind mounts and environment files; missing storage blocks startup.
Both mounts are declared in `modules/server/storage.nix`. The existing Docker
network preparation unit creates application directories on the mounted disk
using tmpfiles rules before starting containers.

Hermes uses a single writable mount from `/mnt/storage/container/hermes` to
`/opt/data`, including its SQLite databases, sessions, configuration, cron jobs,
memories, skills, and soul. Nix-managed plugins are mounted read-only within it.
Other applications retain the internal paths expected by their images, such as
Jellyfin's `/config` and `/cache`. There is no extra `state/` directory and no
recurring database copy job.

The NAS target is `iqn.2005-10.org.freenas.ctl:container`, LUN 0, at
`10.69.1.102:3260`. Allow only the initiator
`iqn.2026-10.local.nixos:nixos-server` to use it, and include `storage/container`
in the TrueNAS snapshot task.

The migration and reboot verification are complete. The original NFS dataset
and local state copies are retained for cleanup; live containers use only the
new storage. The temporary migration helpers are gone after reboot. No SQLite
integrity checks or database repair were performed.

DHCP is limited to the server's `ens18` interface and waits for IPv4 before
marking the network online, so NAS mounts start after the required address is
available.

Deploy container changes by rebuilding the server configuration. Services
routed through the public tunnel or DNS should have suitable access controls.

```bash
sudo systemctl restart docker-traefik
sudo systemctl status 'docker-*'
```

Custom images for Hermes, Hermes Desktop, Executor, and the speaker services are
prepared by `docker-image-*.service` units. Their tags are derived from the
Dockerfile, build context, and an optional `revision` in `lab.mkImage`. A new
recipe is built before its containers start; an existing image is reused on
restarts. Build failures block startup instead of silently falling back to old
images. If pruning removed an unused image, its preparation unit builds it
again on the next start.

To update upstream software without changing a recipe, add or increment
`revision = 2;` in that image's `lab.mkImage` call and rebuild the server. New
images use a clean Docker build; routine container restarts do not rebuild them.
Both desktop containers share the same image preparation unit.

Executor's MCP packages live in its image, so no runtime package installer or
mutable `node_modules` volume is needed. Updating the package manifest prepares
a new image. PostgreSQL units wait up to two minutes for TCP readiness before
dependent containers start.

Environment files are supplied explicitly; services never generate or replace
secret values. Examples are in `modules/server/secrets-examples/`. Fill them in
outside the repository and install them at the configured paths before a fresh
deployment:

- Hindsight: `/mnt/storage/container/secrets/hindsight.env`, mode `0600`, owned by
  root. Its database URL must use the same password as `POSTGRES_PASSWORD`.
- AudioMuse: `/mnt/storage/container/audiomuse/secrets.env`, mode `0600`, owned by `1000:100`.
- Other services: `/mnt/storage/container/secrets/<service>.env`, mode `0600`.

The migration preserves existing environment files and their values. Preserve
them with database backups; changing `POSTGRES_PASSWORD` in the
file does not change the password in an initialized PostgreSQL database.
