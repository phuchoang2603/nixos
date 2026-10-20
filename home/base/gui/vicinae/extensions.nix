{
  pkgs,
  lib,
  inputs,
  ...
}:

let
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
in
{
  programs.vicinae = {
    extensions = [
      inputs.vicinae-extensions.packages.${pkgs.stdenv.hostPlatform.system}.nix
      inputs.vicinae-extensions.packages.${pkgs.stdenv.hostPlatform.system}.process-manager
      inputs.vicinae-extensions.packages.${pkgs.stdenv.hostPlatform.system}.iconify
      inputs.vicinae-extensions.packages.${pkgs.stdenv.hostPlatform.system}.it-tools
      inputs.vicinae-extensions.packages.${pkgs.stdenv.hostPlatform.system}.github
    ]
    ++ lib.optionals isDarwin [
      (pkgs.callPackage ./system-monitor.nix { })
    ];
    settings = {
      favorites = lib.mkAfter (
        [ "@leonkohli/vicinae-extension-process-manager-0:processes" ]
        ++ lib.optionals isDarwin [
          "@hossammourad/store.raycast.raycast-system-monitor:system-monitor"
        ]
      );
      providers = {
        "@leonkohli/vicinae-extension-process-manager-0".preferences = {
          refresh-interval = "2000";
          show-system-processes = true;
          process-limit = "500";
        };
      }
      // lib.optionalAttrs isDarwin {
        "@hossammourad/store.raycast.raycast-system-monitor" = {
          entrypoints.system-monitor.shortcut = "alt+m";
          preferences = {
            defaultView = "system-info";
            displayModeCpu = "used";
            displayModeMemory = "used";
            displayModeDisk = "used";
          };
        };
      };
    };
  };
}
