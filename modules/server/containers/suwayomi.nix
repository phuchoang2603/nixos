{ lab, ... }:

{
  virtualisation.oci-containers.containers = {
    flaresolverr = lab.mkContainer {
      image = "ghcr.io/flaresolverr/flaresolverr:latest";
    };

    suwayomi = lab.mkContainer {
      image = "ghcr.io/suwayomi/suwayomi-server:preview";
      dependsOn = [ "flaresolverr" ];
      volumes = [
        "${lab.media}/manga:/home/suwayomi/data:rw"
        "${lab.appdata}/suwayomi/data:/home/suwayomi/.local/share/Tachidesk:rw"
      ];
      environment = {
        EXTENSION_REPOS = ''["https://raw.githubusercontent.com/keiyoushi/extensions/repo/index.min.json"]'';
        FLARESOLVERR_ENABLED = "true";
        FLARESOLVERR_URL = "http://flaresolverr:8191";
      };
      traefik = {
        name = "suwayomi";
        port = 4567;
      };
    };
  };
}
