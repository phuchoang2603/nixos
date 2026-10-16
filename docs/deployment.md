# Dependency updates and server deployment

Renovate opens overnight updates for flake inputs, `flake.lock`, and T3 Code
nightly releases. The T3 Code rule reads the npm registry's
nightly version and SHA-512 integrity hash for Linux x64 and macOS ARM64,
updating the version and hash together in `home/base/cli/agents/t3-cli.nix`.
Docker images and GitHub Actions are not managed by Renovate.

The `Build nixos-server` workflow validates the automation files and builds the complete
server configuration. Pull requests and merge queues use GitHub-hosted runners;
main pushes and manual main builds use the server's separate build runner once
the repository variable `NIXOS_PERSISTENT_BUILDER` is `true`. Until then they also
use hosted runners. Renovate automatically merges its PRs after required checks pass.
Major updates are included in automerge.

After a successful **push** build on `main`, the `Deploy nixos-server` workflow
runs on the server's self-hosted runner. It requests activation of that exact
commit through `nixos-deploy@COMMIT.service`. GitHub Actions checks the build
result; the service checks that the commit is still `main` before running
`nixos-rebuild switch --flake github:phuchoang2603/nixos/COMMIT#nixos-server`.
Superseded commits are skipped. There is no custom deployment controller or timer.

The runner uses a separate system user and the NixOS runner module's sandbox.
It has no general sudo access: Polkit only permits it to start deployment units
with a full commit SHA. PR code and PR artifacts are never checked out on this
runner by the deployment workflow. Keep additional repository workflows from
assigning untrusted jobs to this runner.

Deployments are serialized and never cancelled midway by a newer push. The
ephemeral runner completes one job, then re-registers with the latest system
configuration so runner updates do not interrupt its active job. Activation can restart changed applications,
including T3 Code, and does not reboot; new kernels need a later reboot.

The build runner uses `github-build`, without deployment permission, sudo, or
Docker access. Each job gets a fresh workspace while the host's Nix store persists.
Hosted builds restore the Nix store from GitHub's cache, retaining up to 12 GB
and keeping the system result rooted through cache upload. The NVIDIA driver and
container toolkit remain installed; GPU containers provide their own CUDA libraries.

One public Cachix cache, `phuchoang2603-nixos`, shares successful main builds with
normal NixOS switches. Its name and public signing key live in
`modules/common/cachix.json`, read by both CI and the common NixOS module.
Upstream Nix caches remain available. Application health and Docker startup are
not tested by the build.

Create the public cache at https://app.cachix.org and put its public signing key
in that JSON file. Save a cache-scoped write token as the repository Actions secret
`CACHIX_AUTH_TOKEN`; never commit the token. CI uploads the successful system
closure. Consumers need no token or repeated `cachix use` command. After activating
the configuration, normal `sudo nixos-rebuild switch --flake .#nixos-server`
automatically checks Cachix. The first switch can use `--option extra-substituters`
and `--option extra-trusted-public-keys` with those same values to use it immediately.

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

5. Bootstrap the server once from this checkout after CI passes:

   ```bash
   sudo nixos-rebuild switch --flake path:.#nixos-server --no-write-lock-file
   ```

   This creates separate build and deploy users, registers runners with labels
   `nixos-server-build` and `nixos-server-deploy`, and installs the deployment service. An old
   runner registration named `nixos-server` is replaced. Future main pushes and
   Renovate merges deploy automatically after CI succeeds.

6. After the build runner appears online in repository Actions settings, enable
   main builds on it:

   ```bash
   gh variable set NIXOS_PERSISTENT_BUILDER --repo phuchoang2603/nixos --body true
   ```

   For an existing deployment installation, the first push remains hosted and
   deploys the new runner before this variable is enabled. Set it to `false` to
   route subsequent main builds back to GitHub-hosted runners.

## Inspect and recover

```bash
systemctl status github-runner-nixos-server
systemctl status github-runner-nixos-server-build
journalctl -u 'nixos-deploy@*' -n 100 --no-pager
```

Failed activations are reported as failed deployment jobs. Review the journal,
fix the configuration, or rerun the failed deployment from GitHub Actions.

To pause automatic activation before a manual rollback:

```bash
sudo systemctl stop github-runner-nixos-server.service
sudo nixos-rebuild switch --rollback
```

Pausing the runner does not cancel an already running deployment. Let that
deployment finish before rolling back. To resume, start
`github-runner-nixos-server.service`.
