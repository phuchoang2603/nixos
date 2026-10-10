{ lab, ... }:

{
  virtualisation.oci-containers.containers.obscura = lab.mkContainer {
    image = "h4ckf0r0day/obscura:latest";
    environmentFiles = [ "${lab.secrets}/obscura.env" ];
    cmd = [
      "mcp"
      "--http"
      "--host"
      "0.0.0.0"
      "--port"
      "3000"
      "--allow-private-network"
    ];
  };
}
