# Dependency updates and server deployment

Renovate opens overnight updates for flake inputs and `flake.lock`, GitHub
Actions, and literal `image = "registry/name:tag"` references in the server's
container modules. Container images are pinned by digest so moving tags such
as `latest` produce reviewable updates. Custom package versions and hashes in
Nix expressions need their own updater and are not covered by this configuration.

The `Build nixos-server` workflow runs deployment tests and builds the complete
server configuration on GitHub-hosted runners for pull requests and pushes to
`main`. Renovate automatically merges its PRs after required checks pass.
Major updates are included in automerge.

After a successful **push** build on `main`, the `Deploy nixos-server` workflow
runs on the server's self-hosted runner. It requests activation of that exact
commit through `nixos-deploy@COMMIT.service`. This root service independently
checks GitHub's current `main` and its successful push build before running
`nixos-rebuild switch --flake github:phuchoang2603/nixos/COMMIT#nixos-server`.
Superseded commits are skipped. Failed checks or API requests prevent deployment.

The runner uses a separate system user and the NixOS runner module's sandbox.
It has no general sudo access: Polkit only permits it to start deployment units
with a full commit SHA. PR code and PR artifacts are never checked out on this
runner by the deployment workflow. Keep additional repository workflows from
assigning untrusted jobs to this runner.

Deployments are serialized and never cancelled midway by a newer push. The
ephemeral runner completes one job, then re-registers with the latest system
configuration so runner updates do not interrupt its active job. Activation can restart changed applications,
including T3 Code, and does not reboot; new kernels need a later reboot.

GitHub's build cache speeds up CI; it is not a binary cache for the server.
The server rebuilds the same pinned commit using its local store and configured
Nix binary caches. Application health and Docker image startup are not tested
by the NixOS build.

## One-time setup

1. Install the [Renovate GitHub App](https://github.com/apps/renovate) and grant
   it access to `phuchoang2603/nixos`.
2. Enable repository auto-merge. Protect `main` with the required GitHub Actions
   check `Build nixos-server`, and require branches to be up to date before
   merging. Do not require review approvals for bot updates. Admin enforcement
   can remain disabled so the repository owner can push directly to `main`;
   deployment still waits for that push's CI result.
3. Create a fine-grained GitHub personal access token scoped to this repository,
   with repository **Administration: read and write**, for runner registration.
   The NixOS module also supports a classic token with `repo` scope. A one-hour
   runner registration token is unsuitable for ongoing runner reconfiguration.
4. On `nixos-server`, store it outside Git and the Nix store:

   ```bash
   sudo install -d -m 0700 /var/lib/github-runner-secrets
   sudo install -m 0600 /dev/null /var/lib/github-runner-secrets/nixos-server.token
   read -rs 'runner_token?Runner registration PAT: '
   printf '\n'
   printf '%s' "$runner_token" | sudo tee /var/lib/github-runner-secrets/nixos-server.token >/dev/null
   unset runner_token
   ```

   The `read` command above uses the server's default Zsh syntax. The file must
   contain only the token, without a trailing newline.

5. Commit and push the repository changes to `main`, then bootstrap the server
   once from this checkout:

   ```bash
   sudo nixos-rebuild switch --flake path:.#nixos-server --no-write-lock-file
   ```

   This creates the runner user, registers the runner with label
   `nixos-server-deploy`, and installs the privileged deployment service. An old
   runner registration named `nixos-server` is replaced. Future main pushes and
   Renovate merges deploy automatically after CI succeeds.

## Inspect and recover

```bash
systemctl status github-runner-nixos-server
journalctl -u 'nixos-deploy@*' -n 100 --no-pager
sudo cat /var/lib/nixos-deploy/last-deployment.json
```

Failed activations are reported as failed deployment jobs and are not recorded
as successful. Review the journal, fix the configuration, or rerun the deploy
workflow. Network/API failures require rerunning the deployment workflow too.

To pause automatic activation before a manual rollback:

```bash
sudo systemctl stop github-runner-nixos-server.service
sudo touch /var/lib/nixos-deploy/paused
sudo nixos-rebuild switch --rollback
```

Pausing the runner does not cancel an already running deployment. Let that
deployment finish before rolling back. To resume, remove
`/var/lib/nixos-deploy/paused` and start `github-runner-nixos-server.service`.
