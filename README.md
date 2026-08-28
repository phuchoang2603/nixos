# NixOS Configuration

Flake-based NixOS setup for a desktop and a headless server, with Home Manager for user-level packages and dotfiles.

## Hosts

| Host | Purpose | Home Manager |
| --- | --- | --- |
| `nixos-desktop` | Hyprland desktop | CLI + GUI (Stylix, Hyprland stack) |
| `nixos-server` | Docker/NFS/NVIDIA server | CLI only |

## Layout

```
flake.nix                 # inputs + nixosConfigurations
hosts/
  nixos-desktop/          # desktop system + monitor overrides
  nixos-server/           # server system + hardware config
home/
  base/cli/               # shared CLI tools, shell, neovim, git, tmux
  base/gui/               # shared GUI (kitty, stylix theming)
  linux/                  # desktop Wayland stack (Hyprland, rofi, waybar, ...)
  server/                 # server home profile (CLI only)
modules/
  common/                 # shared boot, locale, nix settings
  nixos/                  # desktop system modules
  server/                 # server system modules (docker, nfs, nvidia, ssh)
```

## Usage

### Desktop

```bash
nh os switch .#nixos-desktop
# or
sudo nixos-rebuild switch --flake .#nixos-desktop
```

### Server

```bash
nh os switch .#nixos-server
# or
sudo nixos-rebuild switch --flake .#nixos-server
```

`nh os switch .` picks the configuration matching the current hostname.

### Fresh install (desktop)

1. Partition the disk with cfdisk (GPT, 512M EFI + ext4 root).
2. Format and mount:

```bash
sudo mkfs.fat -F 32 -n boot /dev/nvme0n1p1
sudo mkfs.ext4 -L nixos /dev/nvme0n1p2
sudo mount /dev/disk/by-label/nixos /mnt
sudo mkdir -p /mnt/boot
sudo mount /dev/disk/by-label/boot /mnt/boot
```

3. Clone and install:

```bash
sudo git clone https://github.com/phuchoang2603/nixos.git /mnt/etc/nixos
cd /mnt/etc/nixos
sudo cp hosts/nixos-desktop/hardware-configuration.nix /tmp/hw.nix
sudo nixos-generate-config --root /mnt --show-hardware-config | sudo tee hosts/nixos-desktop/hardware-configuration.nix
sudo nixos-install --flake .#nixos-desktop
```

Replace `nixos-desktop` with `nixos-server` for a server install, and use `hosts/nixos-server/hardware-configuration.nix` for hardware config.

## Server notes

- NVIDIA is configured headlessly for Docker GPU workloads (no X11/Wayland display stack).
- NFS mounts to `10.69.1.102` use `nofail` — switch may warn if the NFS host is unreachable.
- `nvidia-container-toolkit-cdi-generator` fails on hosts without an NVIDIA GPU (e.g. QEMU VMs).
