# Dependency updates and server deployment

## Normal workflow

Commit and push infrastructure changes to `main`. GitHub Actions builds that
commit, uploads its system closure to Cachix, then activates it on the server.
Superseded commits are skipped. Failed builds do not deploy.

| Build trigger | Runner | Deploys? |
| --- | --- | --- |
| Push to `main` | `nixos-server-build` on the server | After success |
| Manual run on `main` | `nixos-server-build` | No |
| Pull request, merge queue, or manual run on another branch | GitHub-hosted Ubuntu | No |

The build runner has a fresh workspace and reuses the host's Nix store. Ubuntu
runners restore a GitHub cache with a 12 GB store target. CI validates automation
files and builds NixOS; it does not test application health or build custom Docker
images. Those images are prepared on the server before their containers start.

A separate deployment runner activates the tested commit through
`nixos-deploy@COMMIT.service`. Its only privileged permission is starting that
service. Deployment jobs do not check out PR code. Keep untrusted jobs on hosted
runners. Deployments run one at a time and are not cancelled during activation.

Activation can restart changed services. A reboot is only needed to load a new
kernel or when deliberately staging changes for the next boot.

## Shared Cachix cache

`https://phuchoang2603-nixos.cachix.org` stores successful main builds. Its name
and public signing key live in `modules/common/cachix.json`.

- CI writes with the repository Actions secret `CACHIX_AUTH_TOKEN`.
- NixOS server and desktop read through their common Nix configuration after activation.
- Normal switches need no cache login, token, or repeated `cachix use` command.
- Darwin can use the same cache, but its Nix configuration is not wired to it yet.

Different architectures can share the cache; package reuse requires identical
store paths. The Linux server does not build macOS packages. Upstream caches remain
configured alongside Cachix.

## Dependency updates

Renovate opens overnight updates for flake dependencies and T3 Code nightly
releases. T3 Code's version and npm integrity hash update together in
`home/base/cli/agents/t3-cli.nix`. Docker images and GitHub Actions are not managed
by Renovate. Renovate PRs, including major updates, merge after required checks pass.

## One-time setup

1. Install the [Renovate GitHub App](https://github.com/apps/renovate) for this repo.
2. Enable auto-merge and require the `Build nixos-server` check on `main`, with
   branches up to date. Bot updates need no review approval. Owner pushes can
   bypass this branch rule; deployment still waits for the push build.
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

5. Bootstrap the server once from this checkout. The build runner must be online
   before main CI can run:

   ```bash
   sudo nixos-rebuild switch --flake path:.#nixos-server --no-write-lock-file
   ```

   This creates separate build and deploy users, registers runners with labels
   `nixos-server-build` and `nixos-server-deploy`, and installs the deployment
   service. Future main pushes and Renovate merges deploy after CI succeeds.

The public Cachix cache and its signing key are already configured. For a new
installation, restore a cache-scoped write token as the repository Actions secret
`CACHIX_AUTH_TOKEN`; main builds require it.

## Inspect and recover

```bash
systemctl status github-runner-nixos-server github-runner-nixos-server-build
journalctl -u 'nixos-deploy@*' -n 100 --no-pager
```

Review failed deployment logs, fix the problem, and push or rerun the deployment.
Main builds queue while the build runner is offline.

For a manual rollback, let any active deployment finish, then pause the deployment
runner before switching back:

```bash
sudo systemctl stop github-runner-nixos-server.service
sudo nixos-rebuild switch --rollback
sudo systemctl start github-runner-nixos-server.service
```

## Manual deployment

Apply the local checkout immediately:

```bash
sudo nixos-rebuild switch --flake .#nixos-server
```

To stage a change until reboot, such as work on services carrying your connection:

```bash
sudo nixos-rebuild boot --flake .#nixos-server
sudo reboot
```
