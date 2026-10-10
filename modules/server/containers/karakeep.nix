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

        OPENAI_BASE_URL = "http://cli-proxy-api:8317/v1";
        OPENAI_API_KEY = "cliproxyapi";
        INFERENCE_TEXT_MODEL = "gpt-6-luna";
        INFERENCE_IMAGE_MODEL = "gemini-3-flash";
        INFERENCE_USE_MAX_COMPLETION_TOKENS = "true";
        INFERENCE_CONTEXT_LENGTH = "8192";
        INFERENCE_JOB_TIMEOUT_SEC = "120";
        INFERENCE_ENABLE_AUTO_SUMMARIZATION = "true";

        EMBEDDING_ENABLE_AUTO_INDEXING = "true";
        EMBEDDING_OPENAI_BASE_URL = "https://openrouter.ai/api/v1";
        EMBEDDING_TEXT_MODEL = "openai/text-embedding-3-small";
        EMBEDDING_DIMENSIONS = "1536";
        SEMANTIC_SEARCH_ENABLED = "true";
        RATE_LIMITING_ENABLED = "true";
      };
      traefik = {
        name = "karakeep";
        port = 3000;
      };
    };

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
