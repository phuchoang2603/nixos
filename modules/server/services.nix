{ lib, ... }:

let
  secrets = "/mnt/storage/appdata/secrets";
  appdata = "/mnt/storage/appdata";

  afterNfs = {
    after = [ "nfs-storage-mount.service" ];
    requires = [ "nfs-storage-mount.service" ];
  };

  router = name: host: {
    inherit name;
    value = {
      rule = "Host(`${host}`)";
      entryPoints = [ "websecure" ];
      service = name;
      tls.certResolver = "letsencrypt";
    };
  };

  service = name: port: {
    inherit name;
    value.loadBalancer.servers = [ { url = "http://127.0.0.1:${toString port}"; } ];
  };
in
{
  networking.firewall.allowedTCPPorts = [
    80
    443
  ];

  services.traefik = {
    enable = true;
    environmentFiles = [ "${secrets}/traefik.env" ];
    dataDir = "${appdata}/traefik";
    staticConfigOptions = {
      global = {
        checkNewVersion = false;
        sendAnonymousUsage = false;
      };
      log.level = "INFO";
      api.dashboard = true;
      entryPoints = {
        web = {
          address = ":80";
          http.redirections.entryPoint = {
            to = "websecure";
            scheme = "https";
          };
        };
        websecure.address = ":443";
      };
      certificatesResolvers.letsencrypt.acme = {
        email = "xuanphuc.a1gv@gmail.com";
        storage = "${appdata}/traefik/certs/acme.json";
        caServer = "https://acme-v02.api.letsencrypt.org/directory";
        dnsChallenge = {
          provider = "cloudflare";
          resolvers = [
            "1.1.1.1:53"
            "8.8.8.8:53"
          ];
        };
      };
    };
    dynamicConfigOptions.http = {
      routers = lib.listToAttrs [
        {
          name = "traefik";
          value = {
            rule = "Host(`traefik.home.phuchoang.sbs`)";
            entryPoints = [ "websecure" ];
            service = "api@internal";
            tls.certResolver = "letsencrypt";
          };
        }
        (router "vault" "vault.home.phuchoang.sbs")
        (router "vaultwarden" "vaultwarden.home.phuchoang.sbs")
        (router "karakeep" "karakeep.home.phuchoang.sbs")
        (router "n8n" "n8n.home.phuchoang.sbs")
        (router "suwayomi" "suwayomi.home.phuchoang.sbs")
        {
          name = "proxmox";
          value = {
            rule = "Host(`proxmox.home.phuchoang.sbs`)";
            entryPoints = [ "websecure" ];
            service = "proxmox";
            tls.certResolver = "letsencrypt";
          };
        }
        {
          name = "minio";
          value = {
            rule = "Host(`minio.home.phuchoang.sbs`)";
            entryPoints = [ "websecure" ];
            service = "minio";
            tls.certResolver = "letsencrypt";
          };
        }
      ];
      services = lib.listToAttrs [
        (service "vault" 8200)
        (service "vaultwarden" 8222)
        (service "karakeep" 3000)
        (service "n8n" 5678)
        (service "suwayomi" 4567)
        {
          name = "proxmox";
          value.loadBalancer = {
            servers = [ { url = "https://10.69.1.1:8006"; } ];
            serversTransport = "insecureTransport";
          };
        }
        {
          name = "minio";
          value.loadBalancer.servers = [ { url = "http://10.69.1.102:30212"; } ];
        }
      ];
      serversTransports.insecureTransport.insecureSkipVerify = true;
    };
  };

  services.vault = {
    enable = true;
    address = "127.0.0.1:8200";
    storageBackend = "file";
    storagePath = "${appdata}/vault";
    extraConfig = ''
      ui = true
      api_addr = "http://127.0.0.1:8200"
    '';
  };

  services.vaultwarden = {
    enable = true;
    environmentFile = "${secrets}/vaultwarden.env";
    config = {
      DOMAIN = "https://vaultwarden.home.phuchoang.sbs";
      SIGNUPS_ALLOWED = false;
      WEB_VAULT_ENABLED = true;
      PUSH_ENABLED = true;
      IP_HEADER = "X-Forwarded-For";
      ROCKET_ADDRESS = "127.0.0.1";
      ROCKET_PORT = 8222;
      DATA_FOLDER = "${appdata}/vaultwarden/data";
    };
  };

  services.karakeep = {
    enable = true;
    environmentFile = "${secrets}/karakeep.env";
    extraEnvironment = {
      NEXTAUTH_URL = "https://karakeep.home.phuchoang.sbs";
      PORT = "3000";
    };
  };

  services.n8n = {
    enable = true;
    environment = {
      N8N_HOST = "n8n.home.phuchoang.sbs";
      N8N_PROTOCOL = "https";
      N8N_SECURE_COOKIE = true;
      N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS = true;
      N8N_SKIP_AUTH_ON_OAUTH_CALLBACK = true;
      WEBHOOK_URL = "https://n8n.vps.phuchoang.sbs/";
    };
  };

  services.flaresolverr = {
    enable = true;
    port = 8191;
  };

  services.suwayomi-server = {
    enable = true;
    dataDir = "${appdata}/suwayomi";
    settings.server = {
      ip = "127.0.0.1";
      port = 4567;
      localSourcePath = "/mnt/storage/media/manga";
      extensionRepos = [
        "https://raw.githubusercontent.com/keiyoushi/extensions/repo/index.min.json"
      ];
      flareSolverrEnabled = true;
      flareSolverrUrl = "http://127.0.0.1:8191";
    };
  };

  services.newt = {
    enable = true;
    settings.endpoint = "https://pangolin.vps.phuchoang.sbs";
    environmentFile = "${secrets}/newt.env";
  };

  systemd.services = {
    traefik = afterNfs // {
      serviceConfig.ReadWritePaths = [ "${appdata}/traefik" ];
    };
    vault = afterNfs;
    vaultwarden = afterNfs // {
      serviceConfig = {
        ReadWritePaths = [ "${appdata}/vaultwarden/data" ];
        ProtectHome = lib.mkForce false;
      };
    };
    karakeep-web = afterNfs;
    karakeep-workers = afterNfs;
    karakeep-init = afterNfs;
    n8n = afterNfs;
    suwayomi-server = afterNfs // {
      serviceConfig.ReadWritePaths = [
        "${appdata}/suwayomi"
        "/mnt/storage/media/manga"
      ];
    };
    newt = afterNfs;
  };
}
