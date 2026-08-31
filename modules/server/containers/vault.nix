{ lab, ... }:

{
  virtualisation.oci-containers.containers.vault = lab.mkContainer {
    image = "hashicorp/vault:1.19.0";
    cmd = [ "server" ];
    volumes = [ "${lab.appdata}/vault:/vault/file:rw" ];
    extraOptions = [ "--cap-add=IPC_LOCK" ];
    environment.VAULT_LOCAL_CONFIG = ''
      {
        "storage": { "file": { "path": "/vault/file" } },
        "listener": { "tcp": { "address": "0.0.0.0:8200", "tls_disable": true } },
        "api_addr": "http://0.0.0.0:8200",
        "ui": true,
        "disable_mlock": false
      }
    '';
    traefik = {
      name = "vault";
      port = 8200;
    };
  };
}
