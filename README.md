# Nix Config (NixOS + macOS)

This repo is a flake-based configuration for:

- NixOS (desktop)
- macOS via nix-darwin (macbook)
- Home Manager for user-level packages and dotfiles

It is organized around small, composable system modules under `modules/`,
user modules under `home/`, and thin host entrypoints under `hosts/`.

## Layout

- `flake.nix`: flake inputs + system outputs
- `hosts/`
  - `hosts/nixos-desktop/`: NixOS host entrypoint + hardware config
  - `hosts/macbook/`: nix-darwin host entrypoint
- `home/`
  - `home/base/cli/`: shared CLI modules + `nvim-config`
  - `home/base/gui/`: shared GUI modules (stylix, ghostty, spicetify)
  - `home/linux/gui/`: Linux GUI modules (Hyprland, rofi, waybar, etc.)
  - `home/darwin/gui/`: macOS GUI layer (currently just `base/gui`)
- `modules/`
  - `modules/nixos/`: NixOS modules (boot, desktop, services, apps, input)
  - `modules/darwin/`: nix-darwin modules (system defaults, homebrew)
- `scripts/`: helper scripts used by the desktop (waybar/rofi/etc)

## Flake Outputs

- `nixosConfigurations.nixos-desktop`
- `darwinConfigurations.macbook`

Home Manager is wired into both via the `home-manager.*Modules.home-manager`
module and host-specific profiles:

- `users.${user}.imports = [ ./home/linux/gui ./hosts/nixos-desktop/home.nix ]` (NixOS desktop)
- `users.${user}.imports = [ ./home/darwin/gui ]` (macbook)

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

Profiles live under `home/`:

- `home/base/cli/default.nix`: base CLI toolset (packages, shell, git, starship, tmux, yazi, opencode, neovim)
- `home/base/gui/default.nix`: shared UI (stylix, ghostty, spicetify)
- `home/linux/gui/default.nix`: Linux GUI (rofi, mako, waybar, hyprland, hyprpaper, hyprlock, hypridle, espanso)
- `home/darwin/gui/default.nix`: macOS GUI (currently just `base/gui`)

## Usage

### NixOS

```bash
sudo nixos-rebuild switch --flake .#nixos-desktop
```

### macOS (nix-darwin)

```bash
darwin-rebuild switch --flake .#macbook
```
