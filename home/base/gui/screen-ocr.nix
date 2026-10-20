{ pkgs, lib, ... }:

let
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
  screenOcr = pkgs.writeShellApplication {
    name = "screen-ocr";
    runtimeInputs = [
      pkgs.coreutils
      (pkgs.tesseract.override { enableLanguages = [ "eng" ]; })
    ]
    ++ lib.optionals (!isDarwin) [
      pkgs.grim
      pkgs.slurp
      pkgs.wl-clipboard
    ];
    text = builtins.readFile ./scripts/screen-ocr.sh;
  };
in
{
  config = lib.mkMerge [
    { home.packages = [ screenOcr ]; }
    (lib.mkIf isDarwin {
      programs.aerospace.settings.mode.main.binding.alt-o = "exec-and-forget ${lib.getExe screenOcr}";
    })
    (lib.mkIf (!isDarwin) {
      wayland.windowManager.hyprland.settings.bind = [ "ALT, O, exec, ${lib.getExe screenOcr}" ];
    })
  ];
}
