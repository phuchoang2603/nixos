{ lab, ... }:

{
  virtualisation.oci-containers.containers.cloudflared = lab.mkContainer {
    image = "cloudflare/cloudflared:latest";
    cmd = [
      "tunnel"
      "--no-autoupdate"
      "run"
    ];
    environmentFiles = [ "${lab.secrets}/cloudflared.env" ];
  };
}
