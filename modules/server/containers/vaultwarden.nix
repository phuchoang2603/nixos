{ lab, ... }:

{
  virtualisation.oci-containers.containers.vaultwarden = lab.mkContainer {
    image = "vaultwarden/server:latest";
    volumes = [ "${lab.appdata}/vaultwarden/data:/data:rw" ];
    environmentFiles = [ "${lab.secrets}/vaultwarden.env" ];
    environment = {
      IP_HEADER = "X-Forwarded-For";
      PUSH_ENABLED = "true";
      SIGNUPS_ALLOWED = "false";
      WEB_VAULT_ENABLED = "true";
    };
    traefik = {
      name = "vaultwarden";
      port = 80;
    };
  };
}
