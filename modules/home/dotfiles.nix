{ pkgs, lib, config, ... }:

# Symlink dotfiles that need to be managed outside of Home Manager
# These are primarily files that pywal writes to for dynamic theming

let
  dotfilesPath = "${config.home.homeDirectory}/.config/nix/dotfiles";
in
{
  # XDG config file symlinks
  xdg.configFile = {
    # Hyprland configuration (pywal writes colors.conf)
    "hypr" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/hypr";
      recursive = true;
    };

    # Waybar (pywal writes waybar.css colors)
    "waybar" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/waybar";
      recursive = true;
    };

    # Mako notifications (pywal writes colors)
    "mako" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/mako";
      recursive = true;
    };

    # Rofi launcher (pywal writes colors.rasi)
    "rofi" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/rofi";
      recursive = true;
    };

    # Neovim configuration
    "nvim" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/nvim";
      recursive = true;
    };

    # Espanso text expander
    "espanso" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/espanso";
      recursive = true;
    };

    # Fcitx5 input method
    "fcitx5" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/fcitx5";
      recursive = true;
    };

    # Pywal templates and cache
    "wal" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/wal";
      recursive = true;
    };

    # Ghostty theme file only (config is managed by Home Manager)
    "ghostty/theme" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/ghostty/theme";
    };

    # Spicetify is managed by spicetify-nix (no dotfiles here)
  };
}
