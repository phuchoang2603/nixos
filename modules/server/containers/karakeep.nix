{ lab, ... }:

{
  virtualisation.oci-containers.containers = {
    karakeep = lab.mkContainer {
      image = "ghcr.io/karakeep-app/karakeep:release";
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

    # The entrypoint already passes --no-sandbox and serves CDP on 9222;
    # overriding the remote-debugging flags breaks its port forwarding.
    karakeep-chrome = lab.mkContainer {
      image = "ghcr.io/karakeep-app/karakeep-chrome:latest";
      extraOptions = [ "--init" ];
      cmd = [
        "--disable-gpu"
        "--disable-dev-shm-usage"
        "--hide-scrollbars"
        "--disable-blink-features=AutomationControlled"
        "--window-size=1440,900"
      ];
    };

    # meili_data replaced the 1.11 `meilisearch` dir, which is too old to upgrade
    # in place; the index is rebuilt from Karakeep (Admin > Reindex all bookmarks).
    karakeep-meilisearch = lab.mkContainer {
      image = "getmeili/meilisearch:latest";
      volumes = [ "${lab.appdata}/hoarderr/meili_data:/meili_data:rw" ];
      environmentFiles = [ "${lab.secrets}/karakeep.env" ];
      environment = {
        MEILI_NO_ANALYTICS = "true";
        MEILI_UPGRADE_DB = "true";
      };
    };
  };
}
