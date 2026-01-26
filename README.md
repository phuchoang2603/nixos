# Nix Config (NixOS + macOS)

This repo is a flake-based configuration for:

- NixOS (desktop)
- macOS via nix-darwin (macbook)
- Home Manager for user-level packages and dotfiles

It is organized around small, composable modules under `modules/`
and thin host entrypoints under `hosts/`.

## Layout

- `flake.nix`: flake inputs + system outputs
- `hosts/`
  - `hosts/nixos-desktop/`: NixOS host entrypoint + hardware config
  - `hosts/macbook/`: nix-darwin host entrypoint
- `modules/`
  - `modules/nixos/`: NixOS modules (boot, desktop, services, apps, input)
  - `modules/darwin/`: nix-darwin modules (system defaults, homebrew)
  - `modules/home/`: Home Manager modules (packages, shell, apps)
- `scripts/`: helper scripts used by the desktop (waybar/rofi/etc)

## Flake Outputs

- `nixosConfigurations.nixos-desktop`
- `darwinConfigurations.macbook`

Home Manager is wired into both via the `home-manager.*Modules.home-manager`
module and host-specific profiles:

- `users.${user} = import ./modules/home/profiles/desktop.nix` (NixOS desktop)
- `users.${user} = import ./modules/home/profiles/gui.nix` (macbook)

## NixOS Modules

`modules/nixos/default.nix` imports:

- `modules/nixos/base.nix`
  - bootloader + kernel
  - locale/timezone
  - user `felix`
  - flakes enabled + GC defaults
  - fonts and minimal base packages
- `modules/nixos/desktop.nix`
  - Hyprland session (greetd + tuigreet)
  - portals, polkit, keyring
  - desktop essentials (waybar/mako/rofi/nautilus/etc)
  - fcitx5 input methods
- `modules/nixos/apps.nix`
  - GUI apps (Edge, VS Code, Obsidian, LibreOffice, CopyQ, Sushi, LocalSend, etc)
- `modules/nixos/services.nix`
  - pipewire, bluetooth
  - docker
  - tailscale
  - avahi/udisks/fwupd/openssh

## Home Manager Profiles

Profiles live under `modules/home/profiles/`:

- `cli.nix`: base CLI toolset (packages, shell, git, starship, tmux, yazi, opencode, neovim)
- `gui.nix`: extends `cli.nix` with shared UI (stylix, spicetify)
- `desktop.nix`: extends `gui.nix` with desktop UI (ghostty, rofi, mako, waybar, hyprland,
  hyprpaper, hyprlock, hypridle, espanso)

Module files are grouped by scope:

- `modules/home/cli/`: CLI modules + `nvim-config`
- `modules/home/desktop/`: desktop modules (stylix, Hyprland, UI apps, etc.)

## Usage

### NixOS

```bash
sudo nixos-rebuild switch --flake .#nixos-desktop
```

### macOS (nix-darwin)

```bash
darwin-rebuild switch --flake .#macbook
```

### Home Manager (fast for Stylix/wallpaper changes)

Use this when you only change Home Manager settings like the Stylix image.

```bash
home-manager switch --flake .#felix@nixos-desktop
```

```bash
home-manager switch --flake .#felix@macbook
```
