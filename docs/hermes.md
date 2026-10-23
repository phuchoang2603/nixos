# Hermes and agent tools

Hermes uses CLIProxyAPI for models, Executor for MCP tools, Hindsight for memory,
and a separate desktop for terminal and browser work.

## Open

| Service | Address |
| --- | --- |
| Hermes | https://hermes.home.phuchoang.sbs |
| Desktop viewer | https://desktop.home.phuchoang.sbs |
| Hindsight | https://hindsight.home.phuchoang.sbs |
| CLIProxyAPI | https://cliproxyapi.home.phuchoang.sbs |
| Executor | https://mcp.home.phuchoang.sbs |
| Executor MCP | https://mcp.home.phuchoang.sbs/mcp?mode=passthrough |

Traefik adds Executor's API key on the MCP route. Its web UI keeps its normal login.

## What to edit

Hermes manages its own settings and jobs. Its home is `/opt/data` in the container,
backed by `/mnt/storage/container/hermes/` on the host.

| Path under `/opt/data` | Purpose |
| --- | --- |
| `config.yaml` | Model, tools, MCP, Discord, and gateway settings |
| `SOUL.md` | Personality and standing authorization |
| `skills/` | Editable skills |
| `hindsight/config.json` | Memory-provider settings |
| `cron/` | Native schedules and execution history |

Use Hermes's controls or edit these files directly; they persist across restarts.
A fresh installation needs restored app data or Hermes's setup flow.

Nix owns the [container infrastructure](../modules/server/containers/hermes.nix):
image, mounts, resource limits, and environment-file wiring. Deploy infrastructure
changes through the [deployment workflow](deployment.md).

Chrome keeps its profile in the desktop's persistent home. Container startup clears
the previous container's Chrome lock files so browser automation can reconnect.
If the browser is unavailable, check `/json/version` on port 9222 inside
`hermes-desktop` and its Chrome processes before changing Hermes's settings.

## Internship applications

The hourly monitor is a native Hermes cron job. Manage it through Hermes or its CLI.

```bash
docker exec -it --user 1000:100 --workdir /opt/hermes hermes /bin/bash
hermes cron list
hermes cron edit --help
```

| Location | Purpose |
| --- | --- |
| `/opt/data/skills/productivity/internship-application-assistant/` | Application policy |
| `/opt/data/skills/web/desktop-browser/` | Browser mechanics and ATS references |
| `/home/pn/internships/profile.json` in `hermes-desktop` | Personal answers and experience |
| `/home/pn/internships/` in `hermes-desktop` | Application configuration and progress |
| `/home/pn/scripts/` in `hermes-desktop` | Writable automation scripts |

Edit skills in Hermes; it syncs them to the desktop as needed. Desktop files persist
under `/mnt/storage/container/hermes-desktop/home/` on the host.
The discovery script lives at `/home/pn/scripts/monitor_simplify_jobs.py` in that
same persistent home. Hermes can edit it when the workflow needs changes; container
restarts and Nix deployments preserve those edits. Matching rules live beside it
in `discovery-filters.json`. Run `python3 /home/pn/scripts/test_monitor.py` for offline
checks, then use the monitor's `--dry-run` to preview matches without posting or
changing state. Normal runs serialize discovery, checkpoint
confirmed Discord posts, and retry failed deliveries on the next run. Preserve the
existing application state; `--init` is only for creating a baseline.

The `application-accounts` plugin creates dedicated credentials, stores them in
Hermes's encrypted local vault, and fills account forms. The application workflow
checks results and submits forms. CAPTCHA and device approval require user help.

## Plugins

[One registry](../modules/server/containers/hermes/plugins/default.nix) declares
all three custom plugins, mounted read-only through the same pattern:

| Plugin | Source and purpose |
| --- | --- |
| `application-accounts` | Local code for applicant credentials |
| `realtime-voice` | Local code for Discord voice |
| `hindsight` | Pinned upstream memory provider; patched to exclude cron and subagent transcripts |

Enable or disable plugins through Hermes. Update their source in this repository,
since Hermes's plugin updater cannot replace read-only mounts.

## Other agent services

CLIProxyAPI runs the official [CLIProxyAPI](https://github.com/router-for-me/CLIProxyAPI)
image with native plugins. The UI manages provider accounts
and settings. Persistent state is in `/mnt/storage/container/cliproxyapi/`:
`config/`, `auths/`, `logs/`, and `plugins/`. Inside Docker, its model endpoint
is `http://cli-proxy-api:8317/v1`.

Executor's UI manages MCP integrations. State lives in
`/mnt/storage/container/executor/data/`. Its [image definition](../modules/server/containers/executor.nix)
bundles the Karakeep MCP package. Stdio integrations use `bun`
with `/mcp/node_modules/<package>/<bin>` as the argument.

See [container operations](docker.md#check-and-restart) for logs and restarts,
and [secret editing](macbook.md#edit-server-secrets) for static credentials.
