{ lab, ... }:

{
  virtualisation.oci-containers.containers.newt = lab.mkContainer {
    image = "fosrl/newt";
    extraOptions = [ "--add-host=host.docker.internal:host-gateway" ];
    environmentFiles = [ "${lab.secrets}/newt.env" ];
  };
}
