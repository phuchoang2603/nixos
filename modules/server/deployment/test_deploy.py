import json
import subprocess
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

import deploy as deployment

SHA = "a" * 40
REPO = "phuchoang2603/nixos"


def run(**changes):
    return {
        "head_sha": SHA,
        "head_branch": "main",
        "event": "push",
        "path": ".github/workflows/nixos-server.yml",
        "head_repository": {"full_name": REPO},
        "status": "completed",
        "conclusion": "success",
        "html_url": "https://github.com/phuchoang2603/nixos/actions/runs/123",
        **changes,
    }


class DeploymentTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.state = Path(self.temporary.name)
        self.system = self.state / "running-system"
        self.stamp = self.state / "last-deployment.json"

    def deploy(self, runs, next_commit=SHA, failure=None):
        responses = [{"sha": SHA}, {"workflow_runs": runs}, {"sha": next_commit}]
        with (
            patch.object(deployment, "github", side_effect=responses),
            patch.object(deployment.subprocess, "run", side_effect=failure) as switch,
        ):
            deployment.deploy(
                REPO, "nixos-server", self.state, "/bin/rebuild", SHA, self.system
            )
        return switch

    def test_success_switches_exact_commit_and_records_success(self):
        switch = self.deploy([run()])
        switch.assert_called_once_with(
            [
                "/bin/rebuild",
                "switch",
                "--flake",
                f"github:{REPO}/{SHA}#nixos-server",
                "--no-write-lock-file",
            ],
            check=True,
        )
        self.assertEqual(json.loads(self.stamp.read_text())["commit"], SHA)

    def test_untrusted_or_incomplete_runs_never_switch(self):
        cases = [
            [],
            [run(status="in_progress")],
            [run(conclusion="failure")],
            [run(conclusion="cancelled")],
            [run(event="pull_request")],
            [run(head_sha="b" * 40)],
            [run(head_branch="other")],
            [run(path=".github/workflows/other.yml")],
            [run(head_repository={"full_name": "other/repo"})],
            [run(status="in_progress"), run()],
        ]
        for runs in cases:
            with self.subTest(runs=runs):
                with (
                    patch.object(
                        deployment,
                        "github",
                        side_effect=[{"sha": SHA}, {"workflow_runs": runs}],
                    ),
                    patch.object(deployment.subprocess, "run") as switch,
                    self.assertRaises(RuntimeError),
                ):
                    deployment.deploy(
                        REPO,
                        "nixos-server",
                        self.state,
                        "/bin/rebuild",
                        SHA,
                        self.system,
                    )
                switch.assert_not_called()
                self.assertFalse(self.stamp.exists())

    def test_superseded_main_never_switches(self):
        self.deploy([run()], next_commit="b" * 40).assert_not_called()
        self.assertFalse(self.stamp.exists())

    def test_failed_switch_keeps_previous_success_for_retry(self):
        self.stamp.write_text(json.dumps({"commit": "b" * 40, "system": "previous"}))
        before = self.stamp.read_text()
        with self.assertRaises(subprocess.CalledProcessError):
            self.deploy([run()], failure=subprocess.CalledProcessError(1, "rebuild"))
        self.assertEqual(self.stamp.read_text(), before)

    def test_already_running_commit_does_not_rebuild(self):
        self.stamp.write_text(
            json.dumps({"commit": SHA, "system": str(self.system.resolve())})
        )
        with (
            patch.object(deployment, "github", return_value={"sha": SHA}) as api,
            patch.object(deployment.subprocess, "run") as switch,
        ):
            deployment.deploy(
                REPO, "nixos-server", self.state, "/bin/rebuild", SHA, self.system
            )
        self.assertEqual(api.call_count, 1)
        switch.assert_not_called()

    def test_manual_generation_change_is_detected(self):
        self.stamp.write_text(json.dumps({"commit": SHA, "system": "another-system"}))
        self.deploy([run()]).assert_called_once()

    def test_requested_commit_must_still_be_main(self):
        with (
            patch.object(deployment, "github", return_value={"sha": "b" * 40}),
            patch.object(deployment.subprocess, "run") as switch,
        ):
            deployment.deploy(
                REPO, "nixos-server", self.state, "/bin/rebuild", SHA, self.system
            )
        switch.assert_not_called()
        self.assertFalse(self.stamp.exists())

    def test_invalid_requested_commit_never_calls_github(self):
        with patch.object(deployment, "github") as api, self.assertRaises(ValueError):
            deployment.deploy(
                REPO, "nixos-server", self.state, "/bin/rebuild", "../main", self.system
            )
        api.assert_not_called()

    def test_pause_prevents_deployment_before_any_network_request(self):
        (self.state / "paused").touch()
        with patch.object(deployment, "github") as api, self.assertRaises(RuntimeError):
            deployment.deploy(
                REPO, "nixos-server", self.state, "/bin/rebuild", SHA, self.system
            )
        api.assert_not_called()


if __name__ == "__main__":
    unittest.main()
