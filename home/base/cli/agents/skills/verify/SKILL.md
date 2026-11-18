---
name: verify
description: Prove a change works before reporting it done, from local lint and tests through CI, published images and the running cluster. Use in any repo built on devenv-modules.
---

# Verify a change

Run everything inside the repo's devenv. CI runs the same devenv, so local results match CI.

1. **Static checks:** `devenv tasks run repo:lint`. This runs the shared ast-grep rules and `scripts/lint.sh`.
2. **Tests:** run the tests for what changed, using `bash scripts/check.sh` with the narrowest mode it offers (read its `usage`). Use `devenv tasks run repo:check` only for a full run. Repos without `scripts/check.sh` have no tests.
3. **Rendered manifests:** if the change touches Helm charts and the repo has `scripts/render-diff.sh`, run it. Confirm the diff contains only the intended changes.
4. **CI:** push, then read the runs for the pushed commit.
   - `gh run list --commit "$(git rev-parse HEAD)"`, then `gh run watch <id> --exit-status`, then `gh run view <id> --log-failed` on failure.
   - Test evidence is in each job's step summary and in `*-evidence-*` artifacts (`gh run download <id>`).
   - For OpenTofu roots, read the plan in the Provision run log. A change that touches no root must plan no changes.
5. **Images and deploy:** when the repo publishes images, confirm the image workflow pushed the expected tag and moved the deploy ref (`deploy/dev`, `deploy/prod`). The tag scheme is in that workflow.
6. **Cluster:** for deployed changes, use the `talos-k8s` skill for access. Check that the affected Argo CD Applications are `Synced` and `Healthy` at the new revision.
7. **Public endpoint:** when the change is user-facing, `curl -fsSI` the hostname from the chart values and expect a 2xx or 3xx.

Report each step's actual result. Name any step you skipped, and say why.
