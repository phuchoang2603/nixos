# Server

## Install

Boot the NixOS USB in UEFI mode with internet access. Keep a copy of this
repository on USB or in the installer filesystem.

**Fresh installation only: these commands erase the selected OS disk.**
The example uses `/dev/sda`; adjust it to your machine. Never select the NAS disk.

```bash
sudo -i
nix-shell -p util-linux e2fsprogs dosfstools openssh nano
lsblk
cfdisk /dev/sda
```

Create a GPT table with partition 1: **1 GiB, EFI System**;
partition 2: **remaining space, Linux filesystem**. Write the table and quit.

```bash
udevadm settle
mkfs.fat -F 32 /dev/sda1
mkfs.ext4 /dev/sda2
mount /dev/sda2 /mnt
mkdir -p /mnt/boot /mnt/etc
mount /dev/sda1 /mnt/boot
cp -a /path/to/nixos /mnt/etc/nixos
cd /mnt/etc/nixos
nixos-generate-config --root /mnt --show-hardware-config \
  > hosts/nixos-server/hardware-configuration.nix
ip -br link
```

If the network interface is not `ens18`, update that name in
`hosts/nixos-server/default.nix`.

### NAS storage

Reuse the existing TrueNAS LUN and media export; NixOS connects and mounts them
automatically. Only one server may use the LUN at a time.

For a new LUN, complete [NAS disk setup](server-storage.md) before continuing.

### Boot decryption

If restoring the host key already listed in `agenix-rules.nix`, restore its
private and public files into `/mnt/etc/ssh` and skip to [Build](#build).
Otherwise, create the new server's host key:

```bash
mkdir -p /mnt/etc/ssh
ssh-keygen -t ed25519 -N '' -f /mnt/etc/ssh/ssh_host_ed25519_key
cat /mnt/etc/ssh/ssh_host_ed25519_key.pub
```

On the MacBook with Nix installed, replace the `server` key in
`secrets/server/agenix-rules.nix` with the printed public key. Keep the MacBook key.

```bash
cd /path/to/nixos
nano secrets/server/agenix-rules.nix
cd secrets/server
nix --extra-experimental-features 'nix-command flakes' \
  run --inputs-from ../.. agenix -- --rekey -i ~/.ssh/id_ed25519
```

Bring the updated `secrets/server/` directory back to the installer using your
USB drive or existing transfer method. Copy it in the installer root shell:

```bash
cd /mnt/etc/nixos
cp -a /path/to/updated/secrets/server/. secrets/server/
```

### Build

In the installer root shell:

```bash
cd /mnt/etc/nixos
nixos-install --flake .#nixos-server
reboot
```

After reboot, log in as root on the console and run `passwd felix`.

## Rebuild

Stage changes for the next boot, keeping services running until you reboot:

```bash
cd /path/to/nixos
sudo nixos-rebuild boot --flake .#nixos-server
sudo reboot
```
