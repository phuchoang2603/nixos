{
  config,
  pkgs,
  lib,
  ...
}:

let
  jsonFormat = pkgs.formats.json { };
  tomlFormat = pkgs.formats.toml { };
in
{
  config = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
    xdg.dataFile =
      lib.listToAttrs (
        map (
          extension: lib.nameValuePair "vicinae/extensions/${extension.name}" { source = extension; }
        ) config.programs.vicinae.extensions
      )
      // {
        "vicinae/themes/stylix.toml".source =
          tomlFormat.generate "vicinae-stylix.toml" config.programs.vicinae.themes.stylix;
      };
    xdg.configFile."vicinae/base.json".source =
      jsonFormat.generate "vicinae-base.json" config.programs.vicinae.settings;

    home.packages = [ pkgs.vicinae ];
    home.activation.setupLaunchAgents = lib.hm.dag.entryAfter [ "copyApps" ] (lib.mkDefault "");

    launchd.agents.vicinae = {
      enable = true;
      config = {
        EnvironmentVariables = {
          VICINAE_NODE_BIN = lib.getExe pkgs.nodejs;
          VICINAE_OVERRIDES = "${config.xdg.configHome}/vicinae/base.json";
          PATH = "/etc/profiles/per-user/${config.home.username}/bin:/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin";
        };
        RunAtLoad = true;
        KeepAlive = true;
        ProcessType = "Interactive";
      };
    };
  };
}
