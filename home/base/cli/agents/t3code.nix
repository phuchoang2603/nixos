{
  config,
  lib,
  pkgs,
  ...
}:

let
  t3codePort = 3773;
  t3codePkg = config.programs.t3code.package;

  t3CloudEnv = {
    T3CODE_RELAY_URL = "https://relay.t3.codes";
    T3CODE_CLERK_PUBLISHABLE_KEY = "pk_live_Y2xlcmsudDMuY29kZXMk";
    T3CODE_CLERK_CLI_OAUTH_CLIENT_ID = "hzxSgY2cH10sDU2r";
  };
in
{
  home.sessionVariables = t3CloudEnv;

  programs.t3code = {
    enable = true;
  };

  systemd.user.services.t3code = lib.mkIf pkgs.stdenv.isLinux {
    Unit = {
      Description = "T3 Code headless server";
      After = [ "network-online.target" ];
      Wants = [ "network-online.target" ];
    };
    Service = {
      Type = "simple";
      Environment = [
        "T3CODE_RELAY_URL=${t3CloudEnv.T3CODE_RELAY_URL}"
        "T3CODE_CLERK_PUBLISHABLE_KEY=${t3CloudEnv.T3CODE_CLERK_PUBLISHABLE_KEY}"
        "T3CODE_CLERK_CLI_OAUTH_CLIENT_ID=${t3CloudEnv.T3CODE_CLERK_CLI_OAUTH_CLIENT_ID}"
      ];
      ExecStart = "${lib.getExe' t3codePkg "t3"} serve --host 0.0.0.0 --port ${toString t3codePort}";
      Restart = "on-failure";
      RestartSec = 5;
    };
    Install.WantedBy = [ "default.target" ];
  };
}
