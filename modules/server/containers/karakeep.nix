{ lab, ... }:

{
  virtualisation.oci-containers.containers = {
    karakeep = lab.mkContainer {
      image = "ghcr.io/karakeep-app/karakeep:0.31.0";
      dependsOn = [
        "karakeep-chrome"
        "karakeep-meilisearch"
      ];
      volumes = [ "${lab.appdata}/hoarderr/data:/data:rw" ];
      environmentFiles = [ "${lab.secrets}/karakeep.env" ];
      environment = {
        PUID = "1000";
        PGID = "1000";
        DATA_DIR = "/data";
        MEILI_ADDR = "http://karakeep-meilisearch:7700";
        BROWSER_WEB_URL = "http://karakeep-chrome:9222";
        NEXTAUTH_URL = "https://${lab.fqdn "karakeep"}";
      };
      traefik = {
        name = "karakeep";
        port = 3000;
      };
    };

    karakeep-chrome = lab.mkContainer {
      image = "gcr.io/zenika-hub/alpine-chrome:123";
      cmd = [
        "--no-sandbox"
        "--disable-gpu"
        "--disable-dev-shm-usage"
        "--remote-debugging-address=0.0.0.0"
        "--remote-debugging-port=9222"
        "--hide-scrollbars"
      ];
    };

    karakeep-meilisearch = lab.mkContainer {
      image = "getmeili/meilisearch:v1.11.1";
      volumes = [ "${lab.appdata}/hoarderr/meilisearch:/meili_data:rw" ];
      environmentFiles = [ "${lab.secrets}/karakeep.env" ];
      environment.MEILI_NO_ANALYTICS = "true";
    };
  };
}
