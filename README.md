# Nix Config (NixOS + macOS)

Flake-based configuration for three hosts:


| Host            | Platform | Purpose                  | Home Manager                       |
| --------------- | -------- | ------------------------ | ---------------------------------- |
| `nixos-desktop` | NixOS    | Hyprland desktop         | CLI + GUI (Stylix, Hyprland stack) |
| `nixos-server`  | NixOS    | Docker/NFS/NVIDIA server | CLI only                           |
| `macbook`       | macOS    | nix-darwin laptop        | CLI + GUI (Stylix, AeroSpace)      |


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
  server/                 # server system modules (nfs, nvidia, ssh, services)
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

## Server notes

- NVIDIA is configured headlessly (no desktop/display stack).
- NFS mounts wait for DHCP before mounting (boot race fix).

### Services

Native NixOS modules in `modules/server/services.nix`, reverse-proxied by Traefik:

`traefik` `vault` `vaultwarden` `karakeep` `n8n` `suwayomi` `flaresolverr` `newt`

Secrets live on NFS at `/mnt/storage/appdata/secrets/`. Copy from `modules/server/secrets-examples/`. Traefik ACME certs: `/mnt/storage/appdata/traefik/certs/`.

After switch, chown NFS data dirs to the service users if they were previously owned by Docker's uid 1000:

```bash
sudo chown -R traefik:traefik /mnt/storage/appdata/traefik
sudo chown -R vault:vault /mnt/storage/appdata/vault
sudo chown -R vaultwarden:vaultwarden /mnt/storage/appdata/vaultwarden
sudo chown -R suwayomi:suwayomi /mnt/storage/appdata/suwayomi
```

n8n and karakeep/meilisearch use `/var/lib/...` (copy from NFS if you want to keep old Docker data).

```bash
sudo systemctl status traefik vaultwarden n8n karakeep-web suwayomi-server newt
```

