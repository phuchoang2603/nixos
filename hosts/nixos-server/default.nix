{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/server
  ];

  networking = {
    firewall = {
      interfaces = {
        ens18 = {
          allowedTCPPorts = [ 1313 ];
        };
      };
    };
    hostName = "nixos-server";
  };
}
