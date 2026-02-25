# Nix Config (NixOS + macOS)

This repo is a flake-based configuration for:

- NixOS (desktop, server, laptop)
- macOS via nix-darwin (macbook)
- Home Manager for user-level packages and dotfiles

It is organized around small, composable system modules under `modules/`,
user modules under `home/`, and thin host entrypoints under `hosts/`.

## Layout

- `flake.nix`: flake inputs + system outputs
- `hosts/`
  - `hosts/nixos-desktop/`: NixOS desktop host entrypoint + hardware config
  - `hosts/nixos-server/`: NixOS server host entrypoint + hardware config
  - `hosts/nixos-laptop/`: NixOS laptop host entrypoint
  - `hosts/macbook/`: nix-darwin host entrypoint
- `home/`
  - `home/base/cli/`: shared CLI modules + `nvim-config`
  - `home/base/gui/`: shared GUI modules (stylix, ghostty, spicetify)
  - `home/linux/gui/`: Linux GUI modules (Hyprland, rofi, waybar, etc.)
  - `home/darwin/gui/`: macOS GUI layer (currently just `base/gui`)
- `modules/`
  - `modules/nixos/`: NixOS modules (boot, desktop, services, apps, input)
  - `modules/darwin/`: nix-darwin modules (system defaults, homebrew)

## Usage

### NixOS

1. Partition with cfdisk
   Run cfdisk on your target drive (e.g., /dev/nvme0n1).

```bash
sudo cfdisk /dev/nvme0n1
```

Inside the cfdisk interface:

- Select Label Type: Choose gpt.
- Create Boot Partition: \* Select New. Size: 512M. Type: Select Type and choose EFI System.
- Create Root Partition: \* Select the remaining Free space. Select New (default size uses the rest of the disk). Type: Leave as Linux filesystem (default).
- Write & Quit: Select Write, type yes, then select Quit.

2. Format the Partitions
   Now that the partitions exist, apply the filesystems.

```bash
# Format the EFI partition (usually p1)
sudo mkfs.fat -F 32 -n boot /dev/nvme0n1p1

# Format the Root partition (usually p2)
sudo mkfs.ext4 -L nixos /dev/nvme0n1p2
```

3. Mount to /mnt
   You need to mount the root first so that the boot directory has a physical place to live on the disk.

```bash
# Mount the root partition to /mnt
sudo mount /dev/disk/by-label/nixos /mnt

# Create the boot mount point and mount the EFI partition
sudo mkdir -p /mnt/boot
sudo mount /dev/disk/by-label/boot /mnt/boot
```

4. Clone and Apply
   Now that your environment is staged at /mnt, you can bring in your flake.

```bash
# Clone your repo into the mounted system
sudo git clone https://github.com/phuchoang2603/nixos.git /mnt/etc/nixos

sudo nixos-generate-config --root /mnt --show-hardware-config | sudo tee /mnt/etc/nixos/hardware-configuration.nix

# Install the system
# Using --root /mnt tells NixOS to install to the disk, not the live ISO
sudo nixos-install --flake /mnt/etc/nixos#nixos-desktop
```

5. Change Password with nixos-enter
   If you need to change the root password or any user password after installation:

```bash
# Reboot into the installed system, then run:
sudo nixos-enter --root /mnt -c "passwd root"
sudo nixos-enter --root /mnt -c "passwd felix"
```

### macOS (nix-darwin)

```bash
darwin-rebuild switch --flake .#macbook
```
