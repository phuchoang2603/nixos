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
| `modules/server/containers/<app>.nix` | Image, mounts, settings, and routing |
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

Replace `hermes` with the container name. For Traefik or CLIProxyAPI changes,
use the staged rebuild below when your connection depends on them.

## Change and deploy

Edit the app's Nix file, then stage and reboot when ready:

```bash
cd /path/to/nixos
sudo nixos-rebuild boot --flake .#nixos-server
sudo reboot
```

For credentials, use [Edit server secrets](macbook.md#edit-server-secrets).
Changed encrypted files cause their consuming containers to restart on a normal
rebuild switch.

Custom images are prepared automatically before their containers start and reused
while their tags exist. Edit the recipe to change it, or increase `revision` in
its `lab.mkImage` call to refresh upstream software. Unused images are pruned
daily; application data stays on the NAS disk.
