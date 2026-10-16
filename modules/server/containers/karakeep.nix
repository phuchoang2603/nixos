{ lab, ... }:

{
  virtualisation.oci-containers.containers = {
    karakeep = lab.mkContainer {
      image = "ghcr.io/karakeep-app/karakeep:release";
      dependsOn = [ "karakeep-meilisearch" ];
      volumes = [ "${lab.appdata}/karakeep/data:/data:rw" ];
      environmentFiles = [ "${lab.secrets}/karakeep.env" ];
      environment = {
        PUID = "1000";
        PGID = "1000";
        DATA_DIR = "/data";
        MEILI_ADDR = "http://karakeep-meilisearch:7700";
        NEXTAUTH_URL = "https://${lab.fqdn "karakeep"}";

        # With no browser URL, Karakeep fetches HTML over HTTP without Chrome/JS.
        # Keep text extraction and AI/search, but skip browser-generated assets.
        CRAWLER_NUM_WORKERS = "1";
        CRAWLER_STORE_SCREENSHOT = "false";
        CRAWLER_FULL_PAGE_SCREENSHOT = "false";
        CRAWLER_STORE_PDF = "false";
        CRAWLER_FULL_PAGE_ARCHIVE = "false";
        CRAWLER_VIDEO_DOWNLOAD = "false";

        OPENAI_BASE_URL = "http://omniroute:20128/v1";
        OPENAI_API_KEY = "omniroute";
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
      extraOptions = [ "--cpus=1" ];
      traefik = {
        name = "karakeep";
        port = 3000;
      };
    };

    karakeep-meilisearch = lab.mkContainer {
      image = "getmeili/meilisearch:latest";
      volumes = [ "${lab.appdata}/karakeep/meili_data:/meili_data:rw" ];
      environmentFiles = [ "${lab.secrets}/karakeep.env" ];
      environment = {
        MEILI_NO_ANALYTICS = "true";
        MEILI_UPGRADE_DB = "true";
      };
    };
  };
}
