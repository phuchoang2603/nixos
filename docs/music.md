# Music stack

Jellyfin serves the library. Lidarr catalogs wanted music and imports downloads.
Tubifarry searches and downloads audio from YouTube Music.
AudioMuse analyzes the Jellyfin Music library for recommendations.

## Open

| Service | Address |
| --- | --- |
| Jellyfin | https://jellyfin.home.phuchoang.sbs |
| Lidarr | https://lidarr.home.phuchoang.sbs |
| AudioMuse | https://audiomuse.home.phuchoang.sbs |

## Paths

| Path | Role |
| --- | --- |
| `/mnt/storage/media/music` | Library root; Jellyfin scans it, Lidarr imports into `/music` |
| `/mnt/storage/container/lidarr/config/downloads/youtube` | YouTube download staging; `/config/downloads/youtube` in Lidarr |
| `/mnt/storage/container/lidarr/config` | Lidarr config and Tubifarry plugin state |
| `/mnt/storage/container/jellyfin/` | Jellyfin config and cache |
| `/mnt/storage/container/audiomuse/` | AudioMuse app and Postgres data |

Nix owns the containers: [jellyfin](../modules/server/containers/jellyfin.nix),
[lidarr](../modules/server/containers/lidarr.nix),
[audiomuse](../modules/server/containers/audiomuse.nix).

## Lidarr + Tubifarry + YouTube Music

1. Open Lidarr, finish the wizard, and set the root folder to `/music`.
2. Install Tubifarry: **System → Plugins**, enter `Tubifarry@TypNull#develop`.
3. Configure Tubifarry's YouTube Music indexer and YouTube download client, using
   `/config/downloads/youtube` for staging and audio extraction without re-encoding.
   Enable the shared FFmpeg provider under **Settings → Metadata**. Set the
   generator URL in both providers to `http://lidarr-youtube-session:4416`.
   The session helper has no public port. YouTube may still require account
   cookies; provide their container path in both providers when needed.
4. Enable Tubifarry's Lyrics Enhancer under **Settings → Metadata**, use LRCLIB,
   save `.lrc` files with synced lyrics preferred, and enable scheduled updates
   every 7 days without overwriting existing files. Enable **Media Management →
   Advanced → Import Extra Files** and include `lrc` (`elrc,lrc,srt` is configured).

Tubifarry writes lyrics beside songs in `/music`; Jellyfin reads those sidecars.
Jellyfin's duplicate lyrics download schedule is disabled. Its read-only media
mount prevents saving sidecars itself, although it can cache downloaded lyrics
under its config directory.

Completed YouTube downloads land under `/config/downloads/youtube`. Lidarr imports
them into `/music`; Jellyfin picks them up on the next library scan.

See [container operations](docker.md#check-and-restart) for logs and restarts.
