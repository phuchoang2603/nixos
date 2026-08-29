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
  server/                 # server system modules (docker, nfs, nvidia, ssh, stacks)
stacks/                   # docker compose files for nixos-server
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

- NVIDIA is configured headlessly for Docker GPU workloads (no desktop/display stack).
- After a NVIDIA driver update, **reboot the server** before GPU containers will work.
- NFS mounts wait for DHCP before mounting (boot race fix).



### Docker stacks (Nix-managed)

Compose files live in `stacks/` and are deployed by systemd on `nixos-server`:

`traefik` → `vault`, `karakeep`, `n8n`, `immich`, `suwayomi`

Shared env (`APPDATA`, `MEDIA`, `TZ`, `SECRETS_DIR`) is set in `modules/server/stacks.nix`. Secrets go on NFS at `/mnt/storage/appdata/secrets/`.

See `stacks/README.md` for details.

```bash
sudo systemctl restart docker-stack-traefik
sudo systemctl status 'docker-stack-*'
```

### Auto-deploy (GitHub Actions)

Pushes to `main` that touch server-related paths trigger `.github/workflows/deploy-server.yml`, which runs on a self-hosted runner on `nixos-server` and applies the flake with `nh os switch`.

The runner service runs as `root` so deploy jobs can call `nh os switch` directly (no `sudo`).

**One-time setup:**

1. Create a fine-grained GitHub PAT for `phuchoang2603/nixos` with **Administration → Read and write** (covers self-hosted runners). A classic PAT with `repo` scope also works.

2. Store the token on NFS (must exist before the runner service can register):

```bash
echo -n 'ghp_…' | sudo tee /mnt/storage/appdata/secrets/github-runner.token
sudo chmod 600 /mnt/storage/appdata/secrets/github-runner.token
```

3. Apply the config once manually (installs the runner service):

```bash
nh os switch .#nixos-server \
  --build-host felix@nixos-server \
  --target-host felix@nixos-server
```

4. Confirm the runner appears under **GitHub → repo → Settings → Actions → Runners** as `nixos-server`.

After that, server changes pushed to `main` deploy automatically. Trigger manually from the **Actions** tab via **workflow_dispatch** if needed.

If CI deploy fails before the runner config is updated, apply once manually from your laptop (step 3), then re-run the workflow.

```bash
sudo systemctl status github-runner-nixos-server
```

