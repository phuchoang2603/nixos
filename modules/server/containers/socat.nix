{ ... }:

{
  networking.firewall.allowedTCPPorts = [ 2375 ];

  virtualisation.oci-containers.containers.docker-sock-proxy = {
    image = "docksal/socat";
    autoStart = true;
    ports = [ "2375:2375" ];
    volumes = [ "/var/run/docker.sock:/var/run/docker.sock" ];
    extraOptions = [ "--privileged" ];
  };
}
