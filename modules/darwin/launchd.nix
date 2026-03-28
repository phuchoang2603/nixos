{ pkgs, ... }:

{
  launchd.agents.opencode-serve = {
    command = "${pkgs.opencode}/bin/opencode serve";

    serviceConfig = {
      KeepAlive = true;
      RunAtLoad = true;

      StandardOutPath = "/tmp/opencode.out.log";
      StandardErrorPath = "/tmp/opencode.err.log";
    };
  };
}
