{
  config,
  lib,
  pkgs,
  ...
}:

let
  t3codePort = 3773;
  t3codeUnwrapped = pkgs.callPackage ./t3-cli.nix { };
  t3codePkg = config.programs.t3code.package;
in
{
  programs.t3code = {
    enable = true;
    package =
      if pkgs.stdenv.hostPlatform.isLinux then
        pkgs.buildFHSEnv {
          pname = "t3";
          inherit (t3codeUnwrapped) version;
          multiArch = false;
          targetPkgs =
            p: with p; [
              stdenv.cc.cc.lib
              glib
              nss
              nspr
              at-spi2-core
              dbus
              libX11
              libXcomposite
              libXdamage
              libXext
              libXfixes
              libXrandr
              libxcb
              libxkbcommon
              libgbm
              expat
              alsa-lib
              systemd
              fontconfig
              freetype
              dejavu_fonts
              noto-fonts-color-emoji
            ];
          runScript = lib.getExe t3codeUnwrapped;
        }
      else
        t3codeUnwrapped;
  };

  systemd.user.services.t3code = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
    Unit = {
      Description = "T3 Code headless server";
      After = [ "network-online.target" ];
      Wants = [ "network-online.target" ];
    };
    Service = {
      Type = "simple";
      # Local only; remote access goes through T3 Connect.
      ExecStart = "${lib.getExe t3codePkg} serve --host 127.0.0.1 --port ${toString t3codePort}";
      Restart = "on-failure";
      RestartSec = 5;
    };
    Install.WantedBy = [ "default.target" ];
  };
}
