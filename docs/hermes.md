# Hermes and agent tools

Hermes uses OmniRoute for models, Executor for MCP tools, Hindsight for memory,
and a separate desktop for terminal and browser work.

## Open

| Service | Address |
| --- | --- |
| Hermes | https://hermes.home.phuchoang.sbs |
| Desktop viewer | https://desktop.home.phuchoang.sbs |
| Hindsight | https://hindsight.home.phuchoang.sbs |
| OmniRoute | https://omniroute.home.phuchoang.sbs |
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

OmniRoute ([diegosouzapw/OmniRoute](https://github.com/diegosouzapw/OmniRoute))
is the model gateway: dashboard + OpenAI-compatible `/v1` on port 20128, with
Redis for rate limits. Persistent state is in
`/mnt/storage/container/omniroute/data/` (must be writable by uid 1000 so
`storage.sqlite` and `server.env` can be created). Inside Docker the endpoint is
`http://omniroute:20128/v1`.

**First boot:** log in with `INITIAL_PASSWORD` from `omniroute.env` (or
`docker logs omniroute`) and rotate it. Gateway API keys are off
(`REQUIRE_API_KEY=false`); clients can use any placeholder bearer.
Bootstrap secrets (`JWT_SECRET`, `STORAGE_ENCRYPTION_KEY`, `API_KEY_SECRET`)
are written to `server.env` on that volume — do not delete them or encrypted
provider credentials become unreadable.

**Providers:** add OpenCode Zen (free) plus any OAuth/API subscriptions you use.
Prefer `model: auto` (or a free-tier combo) so quota exhaustion falls through
instead of hard-failing. Hermes keeps model id `gemini-3.8-flash-high` via an
OmniRoute alias to `antigravity/gemini-3.8-flash-tiered`.

**Dashboard defaults worth turning on**
- Compression → mode `stacked`, pipeline RTK (`standard`) then Caveman (`full`),
  `applyToToolResults: true` (the 9router-style token saver).
- Leave injection sanitizer on **warn** (Nix already sets this); use **block**
  only if you accept false positives on agent tool traffic.

Executor's UI manages MCP integrations. State lives in
`/mnt/storage/container/executor/data/`. Its [image definition](../modules/server/containers/executor.nix)
bundles Excalidraw and Karakeep MCP packages. Stdio integrations use `bun`
with `/mcp/node_modules/<package>/<bin>` as the argument.

`speaker` and `speaker-player` provide speech and music tools through Executor.
See [container operations](docker.md#check-and-restart) for logs and restarts,
and [secret editing](macbook.md#edit-server-secrets) for static credentials.
