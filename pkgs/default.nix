#
# /home/felix/.config/nix/pkgs/default.nix
#
# Overlay for custom packages
#
final: prev: {
  # Pinned ansible-language-server from NixOS 25.05
  # The package was removed from nixpkgs due to being unmaintained
  ansible-language-server = prev.callPackage ./ansible-language-server.nix {};
}
