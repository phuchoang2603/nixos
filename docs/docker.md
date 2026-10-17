# Docker containers

Nix declares the containers in `modules/server/containers/`. Each runs as a
systemd service named `docker-<container>`. They share the `proxy` network;
Traefik provides HTTPS access.

## Containers

Web names below use `.home.phuchoang.sbs`.

| Containers | Purpose | Web name |
| --- | --- | --- |
| `traefik` | HTTPS routing and certificates | `traefik` |
| `newt` | Pangolin tunnel | — |
| `vaultwarden` | Password vault | `vaultwarden` |
| `karakeep`, `karakeep-meilisearch` | Bookmarks and search | `karakeep` |
| `jellyfin` | Media library | `jellyfin` |
| `slskd` | Soulseek client and music download staging | — |
| `lidarr` | Music catalog; Tubifarry uses it with slskd | `lidarr` |
| `radarr`, `sonarr` | Movie and TV automation | `radarr`, `sonarr` |
| `chaptarr` | Ebook and audiobook automation | `chaptarr` |
| `prowlarr` | Shared torrent and Usenet indexers | `prowlarr` |
| `qbittorrent` | Torrent downloads | `qbittorrent` |
| `flaresolverr` | Cloudflare challenge helper for Prowlarr indexers | — |
| `cantinarr` | Requests and management across the media stack | `cantinarr` |
| `audiomuse`, `audiomuse-db`, `audiomuse-worker` | Music analysis and recommendations | `audiomuse` |
| `hermes` | Agent gateway and dashboard | `hermes` |
| `hermes-desktop`, `hermes-desktop-vnc` | Agent desktop and browser viewer | `desktop` |
| `cli-proxy-api` | Model API gateway | `cliproxyapi` |
| `executor` | MCP integrations and tools | `mcp` |
| `hindsight`, `hindsight-db` | Agent long-term memory | `hindsight` |
| `excalidraw` | Drawing canvas | `excalidraw` |

See [Hermes and agent tools](hermes.md) for the agent services.
See [Music stack](music.md) for Jellyfin, Lidarr, slskd, and AudioMuse.

## Media setup

Open each service at `https://<web-name>.home.phuchoang.sbs` and finish its
initial account setup. Nix creates the containers, storage, and HTTPS routes;
API keys, indexer accounts, quality profiles, and service connections are saved
in the applications' persistent settings.

| Application | Internal address | Library root |
| --- | --- | --- |
| Radarr | `http://radarr:7878` | `/data/movies` |
| Sonarr | `http://sonarr:8989` | `/data/tv` |
| Chaptarr | `http://chaptarr:8789` | `/data/books` and `/data/audiobooks` |
| Lidarr | `http://lidarr:8686` | `/data/music` (existing `/music` remains available) |
| Prowlarr | `http://prowlarr:9696` | — |
| qBittorrent | `http://qbittorrent:8080` | `/data/downloads/torrents` |
| FlareSolverr | `http://flaresolverr:8191` | — |
| Jellyfin | `http://jellyfin:8096` | `/media/movies`, `/media/tv`, `/media/music`, `/media/books`, `/media/audiobooks` |

1. In qBittorrent, sign in as `admin` with the temporary password from
   `docker logs qbittorrent`, then save a permanent password. The initial
   configuration saves downloads under `/data/downloads/torrents`, with
   incomplete downloads in its `incomplete` subdirectory. Existing settings
   are preserved; check these paths if reusing an existing configuration.
2. Add qBittorrent as a download client in Radarr, Sonarr, Lidarr, and Chaptarr,
   using host `qbittorrent`, port `8080`, and the saved credentials. Give each
   application a separate category, such as `radarr`, `sonarr`, `lidarr`, and
   `chaptarr`. Enable completed download handling. Do not set a category save
   path outside `/data/downloads/torrents`.
3. Add your indexers to Prowlarr. Under **Settings → Apps**, connect Radarr,
   Sonarr, and Lidarr using the internal addresses above, their API keys from
   **Settings → General**, and Prowlarr URL `http://prowlarr:9696`. Choose
   **Full Sync**. For Chaptarr, add book indexers through Prowlarr's
   Torznab/Newznab URLs and API key; include ebook and audiobook categories.
   Under **Settings → Indexers → Indexer Proxies**, add FlareSolverr at
   `http://flaresolverr:8191` with a tag such as `cloudflare`, then apply the
   same tag to indexers that need it. Prowlarr uses it when Cloudflare
   protection is detected. FlareSolverr is internal-only and does not
   reliably solve arbitrary CAPTCHAs.
4. Set the library roots above. Chaptarr handles both book formats in one
   instance with separate roots and profiles. In Jellyfin, add movie, TV,
   music, ebook, and audiobook libraries using the paths above. Use the
   **Books** library type for ebooks and audiobooks, keeping their libraries
   separate. Jellyfin's media mount is read-only; imports belong to the
   managers.
5. In Cantinarr, use **Settings → Add Instance** to connect Radarr, Sonarr,
   Chaptarr, and Lidarr with their internal URLs and API keys. Use Chaptarr's
   base URL, without `/ebook` or `/audiobook`. Connect qBittorrent and Jellyfin
   as well. Set **External Address** to
   `https://cantinarr.home.phuchoang.sbs`, choose default instances and
   profiles, and explicitly assign users to the book and music instances.
   Check that **Instant updates** succeeds; callbacks use
   `http://cantinarr:8585`.

The managers mount `/mnt/storage/media` as `/data`; qBittorrent mounts only
its torrent subtree at the same path. Downloads and imports share the NFS
filesystem, allowing hardlinks where the NAS supports them. Existing Lidarr
Soulseek paths are preserved. For torrent hardlinks in an existing Lidarr
library, change its root from `/music` to `/data/music` in the UI and choose
not to move files: both paths already refer to the same host directory.

qBittorrent uses the host's normal internet connection. Peer TCP/UDP port
`6881` is published; its web UI is reached through Traefik. Usenet is an
optional complement: it normally needs a paid provider, an NZB indexer, and
a client such as SABnzbd. Prowlarr and the managers support both protocols;
SABnzbd is not deployed by this configuration.

## Files and storage

| Path | What to change or store |
| --- | --- |
| `modules/server/containers/<app>.nix` | Container infrastructure and declared app settings |
| `modules/server/containers/default.nix` | Which app modules are enabled |
| `modules/server/containers/lab.nix` | Shared container and image helpers |
| `modules/server/docker.nix` | Docker daemon, network, and startup dependencies |
| `modules/server/lib.nix` | Shared NAS address, paths, and domain |
| `modules/server/storage.nix` | iSCSI and NFS mounts |
| `secrets/server/*.age` | Static encrypted environment files |
| `/mnt/storage/container/<app>/` | Persistent application data and databases on iSCSI |
| `/mnt/storage/media/` | Media on NFS |
| `/run/agenix/` | Root-readable decrypted environment files in RAM |

Containers wait for their required mounts. Application directories are created
automatically on the mounted disk. Docker images remain on the host disk.
Application-managed tokens and credentials remain in persistent app data.

## Check and restart

```bash
docker ps
systemctl --failed
docker logs --tail 50 hermes
sudo journalctl -u docker-hermes -n 50 --no-pager
```

Restart a chosen application through systemd:

```bash
sudo systemctl restart docker-hermes
```

Replace `hermes` with the container name. App-managed settings can be edited in
the app or its persistent files. Hermes's [settings, skills, and cron jobs](hermes.md#what-to-edit)
stay outside Nix.

## Change and deploy

Edit Nix infrastructure or plugin source, then commit and push to `main`.
The [deployment workflow](deployment.md) builds and activates the change.
That guide also covers manual switches, staging for reboot, and rollback.

Edit static credentials through [agenix](macbook.md#edit-server-secrets).
Changed encrypted files restart their consuming containers on a normal switch.

Custom images are prepared automatically before their containers start and reused
while their tags exist. Edit the recipe to change it, or increase `revision` in
its `lab.mkImage` call to refresh upstream software. Unused images are pruned
daily; application data stays on the NAS disk.
