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
| `explo` | Music discovery and downloads | `explo` |
| `audiomuse`, `audiomuse-db`, `audiomuse-worker` | Music analysis and recommendations | `audiomuse` |
| `hermes` | Agent gateway and dashboard | `hermes` |
| `hermes-desktop`, `hermes-desktop-vnc` | Agent desktop and browser viewer | `desktop` |
| `cli-proxy-api` | Model API gateway | `cliproxyapi` |
| `executor` | MCP integrations and tools | `mcp` |
| `hindsight`, `hindsight-db` | Agent long-term memory | `hindsight` |
| `speaker`, `speaker-player` | Speech and music playback | — |
| `excalidraw` | Drawing canvas | `excalidraw` |

See [Hermes and agent tools](hermes.md) for the agent services.

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
