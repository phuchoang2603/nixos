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

The `application-accounts` plugin lets the agent create applicant credentials without
an interactive password prompt. `browser_application_account` generates a unique
password, saves it in Hermes' encrypted local vault, and fills registration and
confirmation fields. Later calls reuse the same credential. It does not submit the
form or confirm account creation; the application workflow checks the site's response.
Interactive Vault tools are disabled through `agent.disabled_toolsets`; `browser_exec`
and the account helper remain enabled. No upstream account-policy patch is needed.

Skills stay editable in Hermes, alongside its other skills, outside this repository:

- `/opt/data/skills/productivity/internship-application-assistant/`: application policy.
- `/opt/data/skills/web/desktop-browser/`: browser mechanics and ATS references.

On the host these live under `/mnt/storage/container/hermes/skills/`. Hermes syncs
skills into the desktop sandbox's `~/.hermes/skills/` when needed. Edit the main
Hermes copy or use its skill tools; Nix deployments do not replace the skills.

The repository owns `hermes/SOUL.md`, the plugins, and
`hermes/scripts/monitor_simplify_jobs.py`, mounted read-only. Personal answers remain
in the private desktop `/home/pn/internships/profile.json`; credentials, sessions
and progress remain writable.
`applicationJob` in `hermes.nix` declares the hourly job. A small startup reconciler
uses Hermes's scheduler API to update only that named job, preserving its ID, history
and next run when unchanged. CAPTCHA and device approval remain user handoffs.

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

Pushing to `main` runs **Build nixos-server**. A successful push build triggers
**Deploy nixos-server** on the local runner, which runs `nixos-rebuild switch` for
that commit. PR builds and manual build runs do not deploy. Superseded commits
are skipped. For manual deployment, use the [Docker rebuild workflow](docker.md#change-and-deploy).
Edit static credentials using [agenix on the MacBook](macbook.md#edit-server-secrets).
