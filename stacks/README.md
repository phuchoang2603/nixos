# Docker stacks

Compose files for `nixos-server`, deployed by systemd (`docker-stack-*`).

## Shared environment

These are set in `modules/server/stacks.nix` and passed to every stack service:

| Variable      | Default                    | Used for                          |
|---------------|----------------------------|-----------------------------------|
| `APPDATA`     | `/mnt/storage/appdata`     | Persistent app data on NFS        |
| `MEDIA`       | `/mnt/storage/media`       | Shared media library on NFS       |
| `TZ`          | `America/New_York`         | Container timezone                |
| `SECRETS_DIR` | `/mnt/storage/appdata/secrets` | Secret env files on NFS       |

Compose files reference these with `${APPDATA}`, `${MEDIA}`, `${TZ}`, and `${SECRETS_DIR}`.

## Secrets

Only secret values live on NFS — not in this repo:

```
/mnt/storage/appdata/secrets/
  traefik.env    # CF_DNS_API_TOKEN
  n8n.env        # DOMAIN_NAME, SUBDOMAIN, …
  karakeep.env   # NEXTAUTH_SECRET, MEILI_MASTER_KEY, …
  immich.env     # DB_PASSWORD, IMMICH_VERSION, …
```

Copy from the `*.example` files in each stack directory, then fill in real values.

## Traefik config

Static config under `traefik/config/` is synced to `${APPDATA}/traefik/config/` on each `docker-stack-traefik` start. Certs persist at `${APPDATA}/traefik/certs/`.

## Stacks

| Stack     | Data paths                                              |
|-----------|---------------------------------------------------------|
| traefik   | `${APPDATA}/traefik/{config,certs}`                     |
| vault     | `${APPDATA}/vault`                                      |
| karakeep  | `${APPDATA}/hoarderr/{data,meilisearch}`                |
| n8n       | `${APPDATA}/ai-stack/n8n/storage`, `${MEDIA}/docs`       |
| immich    | `${APPDATA}/immich/{upload,database,model-cache}`       |
| suwayomi  | `${MEDIA}/manga`, `${APPDATA}/suwayomi/{data,koharu}`   |

## Deploy behavior

Each stack is copied to the Nix store independently (`stacks/<name>/` only). Changing one stack only updates that stack's systemd unit, so `nixos-rebuild switch` should only restart the affected containers.

Changing `stackEnv` in `modules/server/stacks.nix` (e.g. `TZ`, `APPDATA`) updates all stack units.

## Commands

```bash
sudo systemctl restart docker-stack-traefik
sudo systemctl status 'docker-stack-*'
```
