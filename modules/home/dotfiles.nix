{ pkgs, lib, config, ... }:

# Symlink dotfiles that need to be managed outside of Home Manager

let
  dotfilesPath = "${config.home.homeDirectory}/.config/nix/dotfiles";
in
{
  # XDG config file symlinks
  xdg.configFile = {

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


  };
}
