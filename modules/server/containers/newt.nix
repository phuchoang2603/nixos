{ lab, ... }:

{
  virtualisation.oci-containers.containers.newt = lab.mkContainer {
    image = "fosrl/newt:latest";
    extraOptions = [ "--add-host=host.docker.internal:host-gateway" ];
    environmentFiles = [ "${lab.secrets}/newt.env" ];
  };
}
