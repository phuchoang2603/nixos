# Nix Config (NixOS + macOS)

This repo is a flake-based configuration for:

- NixOS (desktop)
- macOS via nix-darwin (macbook)
- Home Manager for user-level packages and dotfiles

It is organized around small, composable modules under `modules/` and thin host entrypoints under `hosts/`.

## Layout

- `flake.nix`: flake inputs + system outputs
- `hosts/`
  - `hosts/nixos-desktop/`: NixOS host entrypoint + hardware config
  - `hosts/macbook/`: nix-darwin host entrypoint
- `modules/`
  - `modules/nixos/`: NixOS modules (boot, desktop, services, apps, input)
  - `modules/darwin/`: nix-darwin modules (system defaults, homebrew)
  - `modules/home/`: Home Manager modules (packages, shell, apps)
- `dotfiles/`: out-of-store dotfiles synced into `~/.config` via Home Manager
- `scripts/`: helper scripts used by the desktop (waybar/rofi/etc)

## Flake Outputs

- `nixosConfigurations.nixos-desktop`
- `darwinConfigurations.macbook`

Home Manager is wired into both via the `home-manager.*Modules.home-manager` module and
host-specific profiles:

- `users.${user} = import ./modules/home/profiles/desktop.nix` (NixOS desktop)
- `users.${user} = import ./modules/home/profiles/gui.nix` (macbook)

## NixOS Modules

`modules/nixos/default.nix` imports:

- `modules/nixos/base/default.nix`
  - bootloader + kernel
  - locale/timezone
  - user `felix`
  - flakes enabled + GC defaults
  - fonts and minimal base packages
- `modules/nixos/desktop/default.nix`
  - Hyprland session (greetd + tuigreet)
  - portals, polkit, keyring
  - desktop essentials (waybar/mako/rofi/nautilus/etc)
  - input methods via `modules/nixos/desktop/input-methods.nix`
- `modules/nixos/apps/default.nix`
  - GUI apps (Edge, VS Code, Obsidian, LibreOffice, CopyQ, Sushi, LocalSend, etc)
- `modules/nixos/services/default.nix`
  - pipewire, bluetooth
  - docker
  - tailscale
  - avahi/udisks/fwupd/openssh
- `modules/nixos/hardware/nvidia.nix`
  - NVIDIA driver defaults for Wayland/Hyprland (imported only by NVIDIA hosts)

## Home Manager Profiles

Profiles live under `modules/home/profiles/`:

- `cli.nix`: base CLI toolset (packages, shell, git, starship, tmux, yazi, opencode, neovim)
- `gui.nix`: extends `cli.nix` with shared UI (stylix, spicetify)
- `desktop.nix`: extends `gui.nix` with desktop UI (ghostty, rofi, mako, waybar, hyprland,
  hyprpaper, hyprlock, hypridle, espanso)

Module files are grouped by scope:

- `modules/home/cli/`: CLI modules + `nvim-config`
- `modules/home/desktop/`: desktop modules (stylix, Hyprland, UI apps, etc.)

## macOS (nix-darwin)

`modules/darwin/default.nix` imports:

- `modules/darwin/system.nix`: macOS defaults + nix settings
- `modules/darwin/homebrew.nix`: homebrew casks list (GUI apps)

## Usage

### NixOS

```bash
sudo nixos-rebuild switch --flake .#nixos-desktop
```

### macOS (nix-darwin)

```bash
darwin-rebuild switch --flake .#macbook
```

### Sanity check

```bash
nix flake check
```
