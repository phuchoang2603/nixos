"""Switch to main only after its exact commit passes the server push workflow."""

import json
import re
import subprocess
import sys
from pathlib import Path
from urllib.parse import urlencode
from urllib.request import Request, urlopen

BRANCH = "main"
WORKFLOW = "nixos-server.yml"


def github(repository, endpoint):
    request = Request(
        f"https://api.github.com/repos/{repository}/{endpoint}",
        headers={
            "Accept": "application/vnd.github+json",
            "X-GitHub-Api-Version": "2022-11-28",
            "User-Agent": "nixos-server-deploy",
        },
    )
    with urlopen(request, timeout=30) as response:
        return json.load(response)


def deploy(
    repository,
    host,
    state,
    rebuild,
    expected_commit,
    current_system=Path("/run/current-system"),
):
    if (state / "paused").exists():
        raise RuntimeError(
            "Automatic deployment is paused; remove the paused file to resume"
        )
    if not re.fullmatch(r"[0-9a-f]{40}", expected_commit):
        raise ValueError("Invalid requested deployment commit")
    commit = github(repository, f"commits/{BRANCH}")["sha"]
    if not re.fullmatch(r"[0-9a-f]{40}", commit):
        raise ValueError("Invalid main commit SHA from GitHub")
    if commit != expected_commit:
        print(
            "Requested commit is no longer main; skipping superseded deployment",
            flush=True,
        )
        return
    stamp = state / "last-deployment.json"
    if stamp.exists():
        previous = json.loads(stamp.read_text())
        if previous == {"commit": commit, "system": str(current_system.resolve())}:
            print(f"Already running {commit}", flush=True)
            return

    query = urlencode(
        {"branch": BRANCH, "event": "push", "head_sha": commit, "per_page": 1}
    )
    runs = github(repository, f"actions/workflows/{WORKFLOW}/runs?{query}")[
        "workflow_runs"
    ]
    # Do not filter by success in the API query: a newer failed/pending run
    # must take precedence over an older success for the same commit.
    if not runs or not all(
        (
            runs[0].get("head_sha") == commit,
            runs[0].get("head_branch") == BRANCH,
            runs[0].get("event") == "push",
            runs[0].get("path") == f".github/workflows/{WORKFLOW}",
            runs[0].get("head_repository", {}).get("full_name") == repository,
            runs[0].get("status") == "completed",
            runs[0].get("conclusion") == "success",
        )
    ):
        raise RuntimeError(f"No successful push CI for {commit}; refusing deployment")

    if github(repository, f"commits/{BRANCH}")["sha"] != commit:
        print(
            "Main advanced while checking CI; skipping superseded deployment",
            flush=True,
        )
        return

    print(f"Deploying {commit}: {runs[0]['html_url']}", flush=True)
    subprocess.run(
        [
            rebuild,
            "switch",
            "--flake",
            f"github:{repository}/{commit}#{host}",
            "--no-write-lock-file",
        ],
        check=True,
    )
    state.mkdir(parents=True, exist_ok=True)
    temporary = state / "last-deployment.json.tmp"
    temporary.write_text(
        json.dumps({"commit": commit, "system": str(current_system.resolve())}) + "\n"
    )
    temporary.replace(stamp)
    print(f"Deployed {commit}", flush=True)


if __name__ == "__main__":
    deploy(sys.argv[1], sys.argv[2], Path(sys.argv[3]), sys.argv[4], sys.argv[5])
