{ ... }:

{
  imports = [
    ./base.nix
    ../cli/packages.nix
    ../cli/shell.nix
    ../cli/git.nix
    ../cli/starship.nix
    ../cli/tmux.nix
    ../cli/yazi.nix
    ../cli/opencode.nix
    ../cli/neovim.nix
  ];
}
