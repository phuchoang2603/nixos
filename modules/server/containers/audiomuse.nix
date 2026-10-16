{
  lab,
  ...
}:

let
  uid = "1000";
  gid = "100";
  state = "${lab.appdata}/audiomuse";
  envFile = "${lab.secrets}/audiomuse.env";
  image = "ghcr.io/neptunehub/audiomuse-ai:3.6.3-nvidia";

  # These seed the database on first startup. After that, change settings in
  # Administration > Setup Wizard; AudioMuse's database is authoritative.
  appEnvironment = {
    POSTGRES_HOST = "audiomuse-db";
    POSTGRES_PORT = "5432";
    POSTGRES_USER = "audiomuse";
    POSTGRES_DB = "audiomuse";
    MEDIASERVER_TYPE = "jellyfin";
    JELLYFIN_URL = "http://jellyfin:8096";
    MUSIC_LIBRARIES = "Music";
    AUTH_ENABLED = "false";
    AUDIOMUSE_USER = "felix";
    AI_MODEL_PROVIDER = "OPENAI";
    OPENAI_SERVER_URL = "http://omniroute:20128/v1/chat/completions";
    OPENAI_MODEL_NAME = "gpt-6-luna";
    OPENAI_API_KEY = "omniroute";
    CLAP_ENABLED = "true";
    LYRICS_ENABLED = "true";
    LYRICS_ASR_ENABLE = "false";
    LYRICS_API_ENABLE = "true";
    LYRICS_API_1_URL_TEMPLATE = "https://lrclib.net/api/get?artist_name={artist}&track_name={title}";
    LYRICS_API_1_ARTIST_PARAM = "artist_name";
    LYRICS_API_1_TITLE_PARAM = "track_name";
    LYRICS_API_1_LYRICS_FIELD = "plainLyrics";
    NEURAL_FINGERPRINT_ENABLED = "false";
    MUSICNN_BATCH_SIZE = "1";
    PER_SONG_MODEL_RELOAD = "false";
    USE_GPU_CLUSTERING = "true";
    CLUSTER_ALGORITHM = "kmeans";
    CLUSTERING_AUTO_CALIBRATION = "true";
    CLUSTERING_RUNS = "200";
    MAX_CONCURRENT_BATCH_JOBS = "1";
    INDEX_BUILD_WORKERS = "1";
    TEMP_DIR = "/app/temp_audio";
    CLAP_OTHER_FEATURES_CACHE_DIR = "/app/cache";
  };
in
{
  systemd.tmpfiles.rules = [
    "d ${state} 0750 ${uid} ${gid} -"
    "d ${state}/web-temp 0750 ${uid} ${gid} -"
    "d ${state}/worker-temp 0750 ${uid} ${gid} -"
    "d ${state}/web-plugins 0750 ${uid} ${gid} -"
    "d ${state}/worker-plugins 0750 ${uid} ${gid} -"
    "d ${state}/backup 0750 ${uid} ${gid} -"
    "d ${state}/model-cache 0750 ${uid} ${gid} -"
    "d ${state}/web-ivf-cache 0750 ${uid} ${gid} -"
  ];

  systemd.services.docker-audiomuse-db = lab.postgresReady "audiomuse-db" "audiomuse";

  virtualisation.oci-containers.containers = {
    audiomuse-db = lab.mkContainer {
      image = "postgres:15-alpine";
      environmentFiles = [ envFile ];
      environment = {
        POSTGRES_USER = "audiomuse";
        POSTGRES_DB = "audiomuse";
      };
      volumes = [ "${state}/postgres:/var/lib/postgresql/data:rw" ];
      extraOptions = [
        "--memory=512m"
        "--cpus=0.5"
      ];
    };

    audiomuse = lab.mkContainer {
      inherit image;
      user = "${uid}:${gid}";
      dependsOn = [ "audiomuse-db" ];
      environmentFiles = [ envFile ];
      environment = appEnvironment // {
        SERVICE_TYPE = "flask";
      };
      # Reuse the same image, without GPU access. CLAP query embeddings and
      # web requests run on CPU; CUDA inference belongs to the worker.
      volumes = [
        "${state}/web-temp:/app/temp_audio:rw"
        "${state}/web-plugins:/app/plugin/installed:rw"
        "${state}/backup:/app/backup:rw"
        "${state}/model-cache:/app/cache:rw"
        "${state}/web-ivf-cache:/app/ivf_cache:rw"
      ];
      ports = [ "127.0.0.1:18000:8000" ];
      extraOptions = [
        "--memory=2g"
        "--cpus=1.5"
        "--security-opt=no-new-privileges"
      ];
      traefik = {
        name = "audiomuse";
        port = 8000;
      };
    };

    audiomuse-worker = lab.mkContainer {
      inherit image;
      user = "${uid}:${gid}";
      dependsOn = [ "audiomuse" ];
      environmentFiles = [ envFile ];
      environment = appEnvironment // {
        SERVICE_TYPE = "worker";
        NVIDIA_VISIBLE_DEVICES = "0";
        NVIDIA_DRIVER_CAPABILITIES = "compute,utility";
      };
      volumes = [
        "${state}/worker-temp:/app/temp_audio:rw"
        "${state}/worker-plugins:/app/plugin/installed:rw"
        "${state}/model-cache:/app/cache:rw"
      ];
      devices = [ "nvidia.com/gpu=all" ];
      extraOptions = [
        "--memory=4g"
        "--cpus=2"
        "--security-opt=no-new-privileges"
      ];
    };
  };
}
