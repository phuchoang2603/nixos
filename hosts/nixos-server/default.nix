{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/server
  ];

  networking = {
    # NAS storage needs IPv4; Docker interfaces must not satisfy DHCP readiness.
    dhcpcd = {
      allowInterfaces = [ "ens18" ];
      wait = "ipv4";
    };
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
