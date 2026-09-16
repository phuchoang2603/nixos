{
  pkgs,
  lib,
  config,
  ...
}:

let
  t3codePort = 3773;
  t3codePkg = config.programs.t3code.package;
in
{
  home.packages = with pkgs; [
    pi-coding-agent
    cursor-cli
    codex
  ];

  programs = {
    t3code = {
      enable = true;
    };

    mcp = {
      enable = true;
      servers = {
        context7 = {
          url = "https://mcp.context7.com/mcp";
        };
      };
    };

  };

  systemd.user.services.t3code = lib.mkIf pkgs.stdenv.isLinux {
    Unit = {
      Description = "T3 Code headless server";
      After = [ "network-online.target" ];
      Wants = [ "network-online.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${lib.getExe' t3codePkg "t3"} serve --host 0.0.0.0 --port ${toString t3codePort}";
      Restart = "on-failure";
      RestartSec = 5;
    };
    Install.WantedBy = [ "default.target" ];
  };
}
