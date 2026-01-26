{ pkgs, lib, config, ... }:

# Symlink dotfiles that need to be managed outside of Home Manager

let
  dotfilesPath = "${config.home.homeDirectory}/.config/nix/dotfiles";
in
{
  # XDG config file symlinks
  xdg.configFile = {
    # Hyprland configuration (managed by Nix)
    "hypr" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/hypr";
      recursive = true;
    };

    # Waybar (theming managed by Stylix)
    "waybar" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/waybar";
      recursive = true;
    };

    # Mako notifications (theming managed by Stylix)
    "mako" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/mako";
      recursive = true;
    };

    # Rofi launcher (theming managed by Stylix)
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



    # OpenCode configuration
    "opencode" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/opencode";
      recursive = true;
    };
  };
}
