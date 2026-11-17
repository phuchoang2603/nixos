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
| Executor | https://executor.sh |
| Executor MCP | https://mcp.executor.sh/mcp |

Executor v2 uses browser sign-in for MCP clients.

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
The desktop container shares Hermes's network namespace, so desktop Chrome is at
`127.0.0.1:9222` for Hermes's native `browser.cdp_url` discovery and CDP tools, and
`hermes-desktop` resolves to loopback for SSH. Restarting Hermes restarts the desktop.

If the browser is unavailable, check `/json/version` on port 9222 inside the Hermes
container before changing Hermes's settings.

## Internship applications

Executor's private **Job Applications** app owns hourly discovery, the applicant profile,
application history and the single active application. Two native Hermes crons use those
records. The hourly prescreen job reads up to 120 new jobs from employer job descriptions
fetched without a browser, marking plausible ones Ready and closing clear rejects. The apply
job runs every 20 minutes in a fresh session and applies to up to two Ready jobs, sequentially. Executor publishes JD summaries, full JD
attachments into one linked Discord task thread per job, then posts each status change
or note as a reply while forum tags track the current state. SQLite owns the thread
mapping and application state; Google Sheets is no longer used.

```bash
docker exec -it --user 1000:100 --workdir /opt/hermes hermes /bin/bash
hermes cron list
hermes cron edit --help
```

| Location | Purpose |
| --- | --- |
| `/opt/data/skills/productivity/internship-application-assistant/` | Application policy and Executor tool workflow |
| `/opt/data/skills/web/desktop-browser/` | Native browser mechanics and ATS references |
| `/opt/data/scripts/job_preflight.py` | Check Executor access, refresh the local profile/resume sources and stage job descriptions before cron |
| `/opt/data/scripts/job_prescreen.py` | Fetch employer job descriptions from ATS APIs for prescreening |
| `/opt/data/skills/web/desktop-browser/scripts/formkit.py` | Form-filling helpers the apply job loads inside `browser_exec`; the agent may fix it, and the preflight restores the last good copy from `/opt/data/browser-helpers/` if an edit breaks it |
| `/home/pn/internships/prescreen/` in `hermes-desktop` | Excerpt batches the cron agent reviews each run |
| `/home/pn/internships/profile.json` in `hermes-desktop` | Private local snapshot of the Executor profile |
| `/home/pn/internships/resume-kit/` in `hermes-desktop` | Resume Publisher sources and local tailoring tools |

Edit skills in Hermes; it syncs them to the desktop as needed. Desktop files persist
under `/mnt/storage/container/hermes-desktop/home/` on the host. Old local discovery,
Sheets files and local Discord state are migration evidence, not the current application tracker.

Executor Resume Publisher supplies versioned sources. Hermes tailors and validates the
per-job PDF locally and records its path, base commit and checksum in Job Applications.
An uncertain submission stays active until portal/email evidence resolves it; it never
expires or automatically retries. Assessments and interviews are recorded as follow-ups
without restarting the submitted application.

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

Executor's hosted UI manages MCP integrations and connected accounts.

See [container operations](docker.md#check-and-restart) for logs and restarts,
and [secret editing](macbook.md#edit-server-secrets) for static credentials.
