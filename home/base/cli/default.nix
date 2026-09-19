{ ... }:

{
  imports = [
    ./packages.nix
    ./shell.nix
    ./tmux.nix
    ./git.nix
    ./yazi.nix
    ./neovim.nix
    ./agents
  ];
}
