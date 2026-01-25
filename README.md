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

Home Manager is wired into both via the `home-manager.*Modules.home-manager` module and `users.${user} = import ./modules/home`.

## NixOS Modules

`modules/nixos/default.nix` imports:

- `modules/nixos/system.nix`
  - bootloader + kernel
  - locale/timezone
  - user `felix`
  - flakes enabled + GC defaults
  - fonts and minimal base packages
- `modules/nixos/desktop.nix`
  - Hyprland session (greetd + tuigreet)
  - portals, polkit, keyring
  - desktop essentials (waybar/mako/rofi/nautilus/etc)
- `modules/nixos/apps.nix`
  - GUI apps (Edge, VS Code, Obsidian, LibreOffice, CopyQ, Sushi, LocalSend, etc)
- `modules/nixos/services.nix`
  - pipewire, bluetooth
  - docker
  - tailscale
  - printing/avahi/udisks/upower/thermald/fwupd
- `modules/nixos/input-methods.nix`
  - fcitx5 + Vietnamese (unikey)
- `modules/nixos/hardware/nvidia.nix`
  - NVIDIA driver defaults for Wayland/Hyprland (imported only by NVIDIA hosts)

## Home Manager Modules

`modules/home/default.nix` imports:

- `modules/home/packages.nix`: main CLI toolset (neovim, kubernetes tools, ripgrep/fd, todoist, etc)
- `modules/home/shell.nix`: zsh config, aliases, functions, completions (includes `zsh-completions`)
- `modules/home/programs.nix`: HM-managed programs (atuin/fzf/zoxide/bat/eza)
- `modules/home/git.nix`: git identity + defaults
- `modules/home/starship.nix`: prompt config
- `modules/home/tmux.nix`: tmux config + plugins
- `modules/home/yazi.nix`: yazi config
- `modules/home/ghostty.nix`: ghostty config
- `modules/home/spicetify.nix`: spicetify-nix integration
- `modules/home/dotfiles.nix`: symlinks repo dotfiles into `~/.config`

### Dotfiles

`modules/home/dotfiles.nix` uses `mkOutOfStoreSymlink` to link `dotfiles/` into `~/.config`.

This is intentional for configs that are edited/updated outside of Home Manager (e.g. pywal-driven theming assets).

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
