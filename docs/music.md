# Music stack

Jellyfin serves the library. Lidarr catalogs wanted music and imports downloads.
slskd is the Soulseek client Tubifarry drives from Lidarr. AudioMuse analyzes the
Jellyfin Music library for recommendations.

## Open

| Service | Address |
| --- | --- |
| Jellyfin | https://jellyfin.home.phuchoang.sbs |
| Lidarr | https://lidarr.home.phuchoang.sbs |
| AudioMuse | https://audiomuse.home.phuchoang.sbs |
| slskd | localhost `5030` (SSH tunnel) |

## Paths

| Path | Role |
| --- | --- |
| `/mnt/storage/media/music` | Library root; Jellyfin scans it, Lidarr imports into `/music` |
| `/mnt/storage/media` | Also mounted as `/data` in Lidarr for shared torrent downloads and libraries |
| `/mnt/storage/container/slskd/downloads` | Shared staging; mounted as `/downloads` in both slskd and Lidarr |
| `/mnt/storage/container/slskd/config` | slskd app data (API key under Options) |
| `/mnt/storage/container/lidarr/config` | Lidarr config and Tubifarry plugin state |
| `/mnt/storage/container/jellyfin/` | Jellyfin config and cache |
| `/mnt/storage/container/audiomuse/` | AudioMuse app and Postgres data |

Nix owns the containers: [jellyfin](../modules/server/containers/jellyfin.nix),
[slskd](../modules/server/containers/slskd.nix),
[lidarr](../modules/server/containers/lidarr.nix),
[audiomuse](../modules/server/containers/audiomuse.nix).

## Lidarr + Tubifarry + slskd

1. Open Lidarr, finish the wizard, and set the root folder to `/music`.
2. Install Tubifarry: **System → Plugins**, enter `Tubifarry@TypNull#develop`.
3. Add Slskd as an **indexer** and **download client** (URL `http://slskd:5030`,
   API key from slskd Options if set). Prefer Soulseek over YouTube; YouTube
   needs cookies and a trusted session and is fragile.
4. Optional: enable Tubifarry's Lyrics Enhancer under **Settings → Metadata**,
   and add `lrc` under **Media Management → Import Extra Files**.

Completed Soulseek grabs land under `/downloads/complete`. Lidarr imports them
into `/music`; Jellyfin picks them up on the next library scan.

See [Media setup](docker.md#media-setup) for Prowlarr, qBittorrent, Cantinarr,
and the movie, TV, ebook, and audiobook services.

See [container operations](docker.md#check-and-restart) for logs and restarts.
