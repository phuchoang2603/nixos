# Media stack

Jellyfin serves movies, shows, music, ebooks, and audiobooks. Radarr, Sonarr, and
Chaptarr manage the libraries; Prowlarr supplies indexers and
qBittorrent downloads torrents. Cantinarr provides requests and management.
FlareSolverr assists protected indexers.

Nix modules live in [`modules/server/containers/media/`](../modules/server/containers/media/).
Its [`default.nix`](../modules/server/containers/media/default.nix) enables the
media services as a group.

## Services

Web names below use `.home.phuchoang.sbs`.

| Containers | Purpose | Web name |
| --- | --- | --- |
| `jellyfin` | Media library | `jellyfin` |
| `radarr`, `sonarr` | Movie and TV automation | `radarr`, `sonarr` |
| `chaptarr` | Ebook and audiobook automation | `chaptarr` |
| `prowlarr` | Shared torrent and Usenet indexers | `prowlarr` |
| `qbittorrent` | Torrent downloads | `qbittorrent` |
| `flaresolverr` | Cloudflare challenge helper for Prowlarr indexers | — |
| `cantinarr` | Requests and management across the media stack | `cantinarr` |

## Setup

Open each service at `https://<web-name>.home.phuchoang.sbs` and finish its
initial account setup. Nix creates the containers, storage, and HTTPS routes;
API keys, indexer accounts, quality profiles, and service connections are saved
in the applications' persistent settings.

| Application | Internal address | Library root |
| --- | --- | --- |
| Radarr | `http://radarr:7878` | `/data/movies` |
| Sonarr | `http://sonarr:8989` | `/data/tv` |
| Chaptarr | `http://chaptarr:8789` | `/data/books/ebooks` and `/data/books/audiobooks` |
| Prowlarr | `http://prowlarr:9696` | — |
| qBittorrent | `http://qbittorrent:8080` | `/data/downloads/torrents` |
| FlareSolverr | `http://flaresolverr:8191` | — |
| Jellyfin | `http://jellyfin:8096` | `/media/movies`, `/media/tv`, `/media/music`, `/media/books` |

1. In qBittorrent, sign in as `admin` with the temporary password from
   `docker logs qbittorrent`, then save a permanent password. The initial
   configuration saves downloads under `/data/downloads/torrents`, with
   incomplete downloads in its `incomplete` subdirectory. Existing settings
   are preserved; check these paths if reusing an existing configuration.
2. Add qBittorrent as a download client in Radarr, Sonarr, and Chaptarr,
   using host `qbittorrent`, port `8080`, and the saved credentials. Give each
   application a separate category, such as `radarr`, `sonarr`, and
   `chaptarr`. Enable completed download handling. Do not set a category save
   path outside `/data/downloads/torrents`.
3. Add your indexers to Prowlarr. Under **Settings → Apps**, connect Radarr
   and Sonarr using the internal addresses above, their API keys from
   **Settings → General**, and Prowlarr URL `http://prowlarr:9696`. Choose
   **Full Sync**. For Chaptarr, add book indexers through Prowlarr's
   Torznab/Newznab URLs and API key; include ebook and audiobook categories.
   Under **Settings → Indexers → Indexer Proxies**, add FlareSolverr at
   `http://flaresolverr:8191` with a tag such as `cloudflare`, then apply the
   same tag to indexers that need it. Prowlarr uses it when Cloudflare
   protection is detected. FlareSolverr is internal-only and does not
   reliably solve arbitrary CAPTCHAs.
4. Set the library roots above. Chaptarr handles both book formats in one
   instance with separate roots and profiles. Ebooks and audiobooks live in
   `/mnt/storage/media/books/ebooks` and `/mnt/storage/media/books/audiobooks`.
   In Jellyfin, add movie and TV libraries using the paths above,
   plus a **Music** library at `/media/music` and one **Books** library at
   `/media/books` covering both subfolders. The configured YouTube playlists
   sync to `/mnt/storage/media/music` daily at 03:00.
   Jellyfin's media mount is read-only; imports belong to the managers.
5. In Cantinarr, use **Settings → Add Instance** to connect Radarr, Sonarr,
   and Chaptarr with their internal URLs and API keys. Use Chaptarr's
   base URL, without `/ebook` or `/audiobook`. Connect qBittorrent and Jellyfin
   as well. Set **External Address** to
   `https://cantinarr.home.phuchoang.sbs`, choose default instances and
   profiles, and assign users to the relevant instances.
   Check that **Instant updates** succeeds; callbacks use
   `http://cantinarr:8585`. Free mobile push notifications use Cantinarr's
   community relay. For completed-file downloads, Cantinarr mounts media
   read-only at `/media`: map `/data/movies` to `/media/movies` in Radarr,
   `/data/tv` to `/media/tv` in Sonarr, and `/data/books/ebooks` to `/media/books/ebooks` plus
   `/data/books/audiobooks` to `/media/books/audiobooks` in Chaptarr.

Cantinarr's Nix environment defaults to **Local (OpenAI-compatible)** with
`gemini-3.8-flash`. Under **Settings → Providers & Credentials**, set its base
URL to `http://cli-proxy-api:8317/v1` and save the proxy token there. Cantinarr
stores the endpoint and encrypted token in its database; saved provider/model
settings override the environment defaults.

The managers mount `/mnt/storage/media` as `/data`; qBittorrent mounts only
its torrent subtree at the same path. Downloads and imports share the NFS
filesystem, allowing hardlinks where the NAS supports them.

qBittorrent uses the host's normal internet connection. Peer TCP/UDP port
`6881` is published; its web UI is reached through Traefik. Usenet is an
optional complement: it normally needs a paid provider, an NZB indexer, and
a client such as SABnzbd. Prowlarr and the managers support both protocols;
SABnzbd is not deployed by this configuration.

See [container operations](docker.md#check-and-restart) for logs and restarts,
and [deployment](deployment.md) for applying changes.
