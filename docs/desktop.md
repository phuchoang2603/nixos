# Desktop

## Install

Boot the NixOS USB in UEFI mode with internet access. Keep a copy of this
repository on USB or in the installer filesystem.

**Fresh installation only: these commands erase the selected OS disk.**
The example uses `/dev/nvme0n1`; adjust the disk and partition paths to your machine.

```bash
sudo -i
nix-shell -p util-linux e2fsprogs dosfstools
lsblk
cfdisk /dev/nvme0n1
```

Create a GPT table with partition 1: **1 GiB, EFI System**;
partition 2: **remaining space, Linux filesystem**. Write the table and quit.

```bash
udevadm settle
mkfs.fat -F 32 /dev/nvme0n1p1
mkfs.ext4 /dev/nvme0n1p2
mount /dev/nvme0n1p2 /mnt
mkdir -p /mnt/boot /mnt/etc
mount /dev/nvme0n1p1 /mnt/boot
cp -a /path/to/nixos /mnt/etc/nixos
cd /mnt/etc/nixos
nixos-generate-config --root /mnt --show-hardware-config \
  > hosts/nixos-desktop/hardware-configuration.nix
nixos-install --flake .#nixos-desktop
reboot
```

After reboot, log in as root on the console and run `passwd felix`.

## Rebuild

```bash
cd /path/to/nixos
sudo nixos-rebuild switch --flake .#nixos-desktop
```
