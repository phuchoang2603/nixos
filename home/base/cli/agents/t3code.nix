{
  config,
  lib,
  pkgs,
  ...
}:

let
  t3codePort = 3773;
  t3codePkg = config.programs.t3code.package;
in
{
  programs.t3code = {
    enable = true;
    package = pkgs.callPackage ./t3-cli.nix { };
  };

  systemd.user.services.t3code = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
    Unit = {
      Description = "T3 Code headless server";
      After = [ "network-online.target" ];
      Wants = [ "network-online.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${lib.getExe t3codePkg} serve --host 0.0.0.0 --port ${toString t3codePort}";
      Restart = "on-failure";
      RestartSec = 5;
    };
    Install.WantedBy = [ "default.target" ];
  };
}
