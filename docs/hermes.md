# Hermes and agent tools

Hermes uses CLIProxyAPI for model requests, Executor for MCP tools, Hindsight
for long-term memory, and a separate desktop for terminal and browser work.

## Open

| Service | Address |
| --- | --- |
| Hermes dashboard | https://hermes.home.phuchoang.sbs |
| CLIProxyAPI | https://cliproxyapi.home.phuchoang.sbs |
| Executor UI | https://mcp.home.phuchoang.sbs |
| Executor MCP endpoint | https://mcp.home.phuchoang.sbs/mcp?mode=passthrough |
| Desktop viewer | https://desktop.home.phuchoang.sbs |
| Hindsight UI | https://hindsight.home.phuchoang.sbs |

Inside Docker, the model API is `http://cli-proxy-api:8317/v1`.
Traefik injects Executor's API key on the `/mcp` route; its web UI uses its normal
login.

## Hermes

Edit [hermes.nix](../modules/server/containers/hermes.nix) for the default model,
MCP connection, memory provider, and gateway settings. Nix merges these managed
settings into the writable `config.yaml` each time Hermes starts.

`/mnt/storage/container/hermes/` mounts at `/opt/data` in the container. It holds
configuration, databases, sessions, skills, memories, cron jobs, and the soul.
Plugins maintained in this repository are mounted read-only.

Related services:

- `hermes-desktop`: terminal, browser, and computer-use sandbox over SSH.
- `hermes-desktop-vnc`: browser access to that desktop.
- `hindsight` and `hindsight-db`: long-term memory and its PostgreSQL database.
- `speaker` and `speaker-player`: speech and music tools available through Executor.

## CLIProxyAPI

Use its management UI to manage provider accounts and configuration.
[cliproxyapi.nix](../modules/server/containers/cliproxyapi.nix) declares the
container and its mounts.

Its data lives under `/mnt/storage/container/cliproxyapi/`:

```text
config/config.yaml  # Writable settings; may also contain credentials
auths/              # Provider login sessions
logs/               # Application logs
plugins/            # Proxy plugins
```

The separate environment file is encrypted in `secrets/server/cliproxyapi.env.age`.

## Executor

Add and configure tool integrations in its web UI. Its persistent data is in
`/mnt/storage/container/executor/data/`, mounted at `/data`.

[executor.nix](../modules/server/containers/executor.nix) builds the image with
Excalidraw, Karakeep, and Proxmox MCP packages installed. Stdio integrations run
with command `bun` and the package's executable path under `/mcp/node_modules/`.
Change that package list in Nix when adding another bundled MCP server.

Local Codex and Cursor configuration lives in
`home/base/cli/agents/`. It shares the Executor endpoint and repository-managed
skills. Codex also uses CLIProxyAPI as its model provider.

## Check and apply changes

```bash
docker logs --tail 50 hermes
docker logs --tail 50 cli-proxy-api
docker logs --tail 50 executor
docker exec -it hermes /bin/bash
```

Deploy Nix changes with the [Docker rebuild workflow](docker.md#change-and-deploy).
Edit static credentials using [agenix on the MacBook](macbook.md#edit-server-secrets).
