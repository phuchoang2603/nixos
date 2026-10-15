{
  config,
  lib,
  pkgs,
  ...
}:
let
  runnerUser = "github-deploy";
  stateDir = "/var/lib/nixos-deploy";
in
{
  users.groups.${runnerUser} = { };
  users.users.${runnerUser} = {
    isSystemUser = true;
    group = runnerUser;
  };

  services.github-runners.nixos-server = {
    enable = true;
    url = "https://github.com/phuchoang2603/nixos";
    name = "nixos-server";
    replace = true;
    ephemeral = true;
    user = runnerUser;
    group = runnerUser;
    tokenFile = "/var/lib/github-runner-secrets/nixos-server.token";
    tokenType = "access";
    extraLabels = [ "nixos-server-deploy" ];
    extraPackages = [ config.systemd.package ];
  };

  # Finish the current job before taking runner changes. An ephemeral runner
  # exits after its job; the module then restarts it with the new configuration.
  systemd.services.github-runner-nixos-server.restartIfChanged = false;

  # The runner retains the module's sandbox. Its only privileged operation is
  # starting this service, which independently checks main and its CI result.
  security.polkit.enable = true;
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (subject.user === "${runnerUser}" &&
          action.id === "org.freedesktop.systemd1.manage-units" &&
          action.lookup("verb") === "start" &&
          /^nixos-deploy@[0-9a-f]{40}\.service$/.test(action.lookup("unit") || "")) {
        return polkit.Result.YES;
      }
    });
  '';

  systemd.services."nixos-deploy@" = {
    description = "Deploy the main commit that passed the server CI build";
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
    restartIfChanged = false;
    unitConfig.X-StopOnRemoval = false;
    environment = config.nix.envVars // config.networking.proxy.envVars;
    path = [
      config.nix.package
      pkgs.gitMinimal
      pkgs.util-linux
    ];
    serviceConfig = {
      Type = "oneshot";
      User = "root";
      StateDirectory = "nixos-deploy";
      StateDirectoryMode = "0700";
      TimeoutStartSec = "2h";
      # Serialize even if separate workflow runs request different commits.
      ExecStart = "${pkgs.util-linux}/bin/flock ${stateDir}/deploy.lock ${pkgs.python3}/bin/python3 ${./deployment/deploy.py} ${
        lib.escapeShellArgs [
          "phuchoang2603/nixos"
          config.networking.hostName
          stateDir
          "${config.system.build.nixos-rebuild}/bin/nixos-rebuild"
        ]
      } %i";
    };
  };
}
