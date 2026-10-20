{
  config,
  pkgs,
  lib,
  ...
}:

{
  config = lib.mkIf (!pkgs.stdenv.hostPlatform.isDarwin) {
    programs.vicinae = {
      enable = true;
      mutableSettings = true;
      systemd.enable = true;
      settings.launcher_window.layer_shell = {
        enabled = true;
        keyboard_interactivity = "on_demand";
      };
    };

    systemd.user.services.vicinae.Service = {
      Environment = [
        "VICINAE_INPUT_SERVER_BIN=/run/wrappers/bin/vicinae-input-server"
        "PATH=${
          pkgs.lib.makeBinPath [
            pkgs.procps
            pkgs.coreutils
          ]
        }:/run/current-system/sw/bin:/etc/profiles/per-user/${config.home.username}/bin"
      ];
    };
  };
}
