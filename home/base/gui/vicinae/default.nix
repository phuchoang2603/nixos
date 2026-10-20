{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

let
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
  jsonFormat = pkgs.formats.json { };
  tomlFormat = pkgs.formats.toml { };
in
{
  config = lib.mkMerge [
    {
      programs.vicinae.extensions = [
        inputs.vicinae-extensions.packages.${pkgs.stdenv.hostPlatform.system}.nix
        inputs.vicinae-extensions.packages.${pkgs.stdenv.hostPlatform.system}.process-manager
      ]
      ++ lib.optionals isDarwin [
        (pkgs.callPackage ./system-monitor.nix { })
      ];
      programs.vicinae.settings = {
        search_files_in_root = false;
        pop_to_root_on_close = true;
        consider_preedit = true;
        favorites = [
          "clipboard:history"
          "snippets:manage"
          "files:search"
          "core:search-emojis"
          "@leonkohli/vicinae-extension-process-manager-0:processes"
        ]
        ++ lib.optionals isDarwin [
          "@hossammourad/store.raycast.raycast-system-monitor:system-monitor"
        ];
        global_shortcuts.toggle = "alt+space";
        providers = {
          calculator.entrypoints.history.shortcut = "alt+c";
          clipboard.entrypoints.history.shortcut = "alt+v";
          files.entrypoints.search.shortcut = "alt+f";
          wm.entrypoints.switch-windows.shortcut = "alt+w";
          "@leonkohli/vicinae-extension-process-manager-0".preferences = {
            refresh-interval = "2000";
            show-system-processes = true;
            process-limit = "500";
          };
        }
        // lib.optionalAttrs isDarwin {
          "@hossammourad/store.raycast.raycast-system-monitor" = {
            entrypoints.system-monitor.shortcut = "alt+s";
            preferences = {
              defaultView = "system-info";
              displayModeCpu = "used";
              displayModeMemory = "used";
              displayModeDisk = "used";
            };
          };
        };
      };
    }
    (lib.mkIf isDarwin {
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
          ProgramArguments = [
            "${config.home.homeDirectory}/${config.targets.darwin.copyApps.directory}/Vicinae.app/Contents/MacOS/Vicinae"
          ];
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
    })
    (lib.mkIf (!isDarwin) {
      programs.vicinae = {
        enable = true;
        mutableSettings = true;
        systemd.enable = true;
        settings.launcher_window.layer_shell.enabled = true;
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
    })
  ];
}
