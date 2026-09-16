{ lab, ... }:

{
  networking.firewall.allowedTCPPorts = [
    80
    443
    3773
  ];

  virtualisation.oci-containers.containers.traefik = lab.mkContainer {
    image = "traefik:v3.6.1";
    extraOptions = [ "--add-host=host.docker.internal:host-gateway" ];
    ports = [
      "80:80"
      "443:443"
    ];
    volumes = [
      "/var/run/docker.sock:/var/run/docker.sock:ro"
      "${./traefik/static.yaml}:/etc/traefik/traefik.yaml:ro"
      "${./traefik/dynamic.yaml}:/etc/traefik/dynamic/external-services.yml:ro"
      "${lab.appdata}/traefik/certs:/var/traefik/certs:rw"
    ];
    environmentFiles = [ "${lab.secrets}/traefik.env" ];
    labels = {
      "traefik.enable" = "true";
      "traefik.http.routers.traefik-dashboard.rule" = "Host(`${lab.fqdn "traefik"}`)";
      "traefik.http.routers.traefik-dashboard.entrypoints" = "websecure";
      "traefik.http.routers.traefik-dashboard.tls" = "true";
      "traefik.http.routers.traefik-dashboard.tls.certresolver" = "letsencrypt";
      "traefik.http.routers.traefik-dashboard.service" = "api@internal";
    };
  };
}
