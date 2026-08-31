{ lab, ... }:

{
  virtualisation.oci-containers.containers.newt = lab.mkContainer {
    image = "fosrl/newt";
    environmentFiles = [ "${lab.secrets}/newt.env" ];
  };
}
