{ pkgs, ... }:

let
  ghosttyCursorShaders = pkgs.fetchFromGitHub {
    owner = "sahaj-b";
    repo = "ghostty-cursor-shaders";
    rev = "0a274beac8b93ee6ce6b94402b7313a0417b8e38";
    hash = "sha256-B7B6K7Ee4uJlW8zzLP3ILgddnbcIQyNimY+rVllzbR0=";
  };
in
{
  programs = {
    ghostty = {
      enable = true;
      package = if pkgs.stdenv.hostPlatform.isDarwin then pkgs.ghostty-bin else pkgs.ghostty;
      settings = {
        # # Font configuration
        font-family = "CaskaydiaCove Nerd Font Mono";
        font-size = 16;

        # Window settings
        confirm-close-surface = false;
        window-decoration = false;
        window-padding-x = 10;
        window-padding-y = 10;
        background-opacity = 0.9;

        # Kitty-like cursor trail
        custom-shader = "${ghosttyCursorShaders}/cursor_tail.glsl";
        custom-shader-animation = "always";

        # Keybind
        keybind = [
          "ctrl+enter=unbind"
        ];
      };
    };
  };
}
