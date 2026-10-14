{
  inputs,
  lib,
  pkgs,
  ...
}:
{
  imports = [ inputs.agenix.nixosModules.default ];

  environment.systemPackages = [ inputs.agenix.packages.${pkgs.stdenv.hostPlatform.system}.default ];

  age.identityPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
  age.verbosity = "summary";
  age.secrets = lib.mapAttrs' (
    file: _:
    lib.nameValuePair (lib.removeSuffix ".age" file) {
      file = ../../secrets/server + "/${file}";
    }
  ) (import ../../secrets/server/agenix-rules.nix);
}
