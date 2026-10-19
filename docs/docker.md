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
| `hermes` | Agent gateway and dashboard | `hermes` |
| `hermes-desktop`, `hermes-desktop-vnc` | Agent desktop and browser viewer | `desktop` |
| `cli-proxy-api` | Model API gateway | `cliproxyapi` |
| `executor` | MCP integrations and tools | `mcp` |
| `hindsight`, `hindsight-db` | Agent long-term memory | `hindsight` |
| `excalidraw` | Drawing canvas | `excalidraw` |
| `siyuan` | Course notes and spaced-repetition flashcards | `siyuan` |

See [Hermes and agent tools](hermes.md) for the agent services.
See [Media stack](media.md) for playback, requests, and downloads.

## SiYuan

Open `https://siyuan.home.phuchoang.sbs` in a browser and use the access code
from the encrypted `siyuan.env` secret. The complete workspace is stored at
`/mnt/storage/container/siyuan/workspace`; it includes source files, diagrams,
flashcards, and review history. The Docker edition is accessed through a browser.

Use one notebook named `Học tập`, with a parent document per course and lesson
documents beneath it. Each course has its own flashcard deck. Add and edit notes
in SiYuan after importing; the original source repository is not needed to study.

The installed `siyuan-import` command imports Markdown and attached source files
through the authenticated SiYuan API. Run `siyuan-import --help` for options.
It creates native question-and-answer flashcards and refuses to overwrite an
existing document with changed source content. Keep the API token in a private
file and pass its path with `--token-file`; never commit it.

`siyuan-backup.timer` makes a daily backup, briefly stopping only SiYuan for a
consistent copy. Archives under `/mnt/storage/container/siyuan/backups` include
the entire workspace and are retained for 30 days. To back up immediately, run
`sudo systemctl start siyuan-backup.service`. To restore, stop `docker-siyuan`,
keep a copy of the current workspace, extract a chosen archive into the SiYuan
state directory, and restart `docker-siyuan`. These backups share the application
storage; copy an archive to separate storage for protection against disk loss.

## Files and storage

| Path | What to change or store |
| --- | --- |
| `modules/server/containers/<app>.nix` | Container infrastructure and declared app settings |
| `modules/server/containers/default.nix` | Which app modules and groups are enabled |
| `modules/server/containers/media/` | Media services and their group imports |
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
