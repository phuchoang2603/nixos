{ lab, ... }:

{
  networking.firewall.allowedTCPPorts = [
    80
    443
  ];

  # Host services proxied via host.docker.internal; reachable from Docker bridges only.
  networking.firewall.interfaces."br-+".allowedTCPPorts = [ 3773 ];

  virtualisation.oci-containers.containers.traefik = lab.mkContainer {
    image = "traefik:latest";
    ports = [
      "80:80"
      "443:443"
    ];
    extraOptions = [ "--add-host=host.docker.internal:host-gateway" ];
    volumes = [
      "/var/run/docker.sock:/var/run/docker.sock:ro"
      "${./traefik/static.yaml}:/etc/traefik/traefik.yaml:ro"
      "${./traefik/dynamic.yaml}:/etc/traefik/dynamic/external-services.yml:ro"
      "${./traefik/executor.yaml}:/etc/traefik/dynamic/executor.yml:ro"
      "${./traefik/t3code.yaml}:/etc/traefik/dynamic/t3code.yml:ro"
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
