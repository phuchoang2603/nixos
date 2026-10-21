{
  config,
  lib,
  pkgs,
  ...
}:
let
  runnerUser = "github-deploy";
  builderUser = "github-build";
  deploy = pkgs.writeShellScript "deploy-nixos-server" ''
    set -euo pipefail
    commit="$1"
    main=$(git ls-remote https://github.com/phuchoang2603/nixos.git refs/heads/main | cut -f1)
    if [[ "$commit" != "$main" ]]; then
      echo "Skipping superseded commit $commit"
      exit 0
    fi
    exec ${config.system.build.nixos-rebuild}/bin/nixos-rebuild switch \
      --flake "github:phuchoang2603/nixos/$commit#${config.networking.hostName}" \
      --no-write-lock-file
  '';
in
{
  users.groups.${runnerUser} = { };
  users.users.${runnerUser} = {
    isSystemUser = true;
    group = runnerUser;
  };
  users.groups.${builderUser} = { };
  users.users.${builderUser} = {
    isSystemUser = true;
    group = builderUser;
  };

  # The job workspace is fresh each time, while /nix/store persists on the host.
  # This account has neither Docker access nor deployment's polkit permission.
  services.github-runners.nixos-server-build = {
    enable = true;
    url = "https://github.com/phuchoang2603/nixos";
    name = "nixos-server-build";
    replace = true;
    ephemeral = true;
    user = builderUser;
    group = builderUser;
    tokenFile = "/var/lib/github-runner-secrets/nixos-server.token";
    tokenType = "access";
    extraLabels = [ "nixos-server-build" ];
    extraPackages = [
      pkgs.cachix
      pkgs.jq
    ];
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
  systemd.services.github-runner-nixos-server-build.restartIfChanged = false;
  systemd.services.github-runner-nixos-server-build.serviceConfig = {
    Restart = lib.mkForce "always";
    RestartSec = "10s";
  };

  # The runner retains the module's sandbox. Its only privileged operation is
  # starting this service. GitHub Actions gates deployment on successful CI.
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
      pkgs.coreutils
    ];
    serviceConfig = {
      Type = "oneshot";
      User = "root";
      TimeoutStartSec = "2h";
      ExecStart = "${deploy} %i";
    };
  };
}
