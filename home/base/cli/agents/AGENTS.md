- Prefer entering a repo's Nix devenv before work (`devenv allow`, `devenv shell`, or the project’s documented equivalent) whenever a devenv/flake/direnv setup exists. Add missing tools to the devenv instead of installing them ad hoc.
- If devenv cannot be used, say so briefly and continue with the closest available tools.
- Do not spawn subagents or delegate work to other agents unless the user explicitly asks for subagents, delegation, or parallel agent work.
- Use Context7 for current public library, SDK, and framework documentation when unsure.

## Code style

- Prefer current, native patterns and remove redundant, stale, unnecessary, or duplicate code.
- Do not preserve legacy compatibility, adapters, fallback paths, or old config formats unless explicitly requested or required by the task. Remove superseded code, dead paths, and stale config, tests, and docs together.
- Update affected producers, consumers, contracts, and configuration in the same change.
- Choose the simplest design with a concrete benefit; justify new abstractions, dependencies, and protocols with a current requirement.
- Split code into files by responsibility instead of growing one large file.
- Do not run formatters by hand when the repo's git hooks format on commit.

## Checks

- Repos built on `devenv-modules` run static checks with `devenv tasks run repo:lint` and everything else, including tests, with `repo:check` in CI inside the same devenv. Run lint locally; do not run tests locally unless asked. Push, then read CI results with `gh`.
- When a repo has a `verify` skill, use it before reporting a change as done.
- Keep devenv tasks and CI steps thin: put the logic in one tracked script that both call, so local and CI run the same check.
- When a mistake can recur, prefer a lint rule, type, test, or script check over a new prose rule.
- Report check results as they are: never present failing, skipped, or pending checks as passing.

## Tests

- Add tests only when asked or when they protect a distinct behavior, boundary, failure mode, or contract.
- Do not add config-only, getter, no-op, implementation-mirroring, or redundant tests. Remove unnecessary tests in the changed area instead of replacing them one-for-one.

## Comments

- Do not add comments unless explicitly asked, or the logic is a non-obvious invariant, protocol quirk, or security caveat that the code cannot express. Prefix such a comment with `NOTE:`; the shared lint rejects other comments apart from doc comments and tool directives.
- Do not add comments that restate the code, narrate the change (`// updated for …`, `// removed …`), or leave migration/history notes. Prefer clear names, tests, and the commit message.
- Keep existing comments, docstrings, and license headers unless the change makes them inaccurate.

## Documentation

- Do not create, rewrite, reformat, or “improve” docs, READMEs, or markdown unless the user explicitly asks, or the change alters user-visible behavior / public API / config that those docs already describe.
- When docs must change, edit only the minimal affected sections; do not restyle or regenerate surrounding content.
- Update existing pages instead of adding per-directory READMEs or repeating information maintained elsewhere.

## Git

- Keep commits small and focused.
