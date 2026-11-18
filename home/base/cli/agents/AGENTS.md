- Work inside the repo's Nix devenv (`devenv shell`, `devenv tasks run`) whenever one exists. Add missing tools to the devenv instead of installing them ad hoc. If devenv cannot be used, say so briefly and continue with the closest available tools.
- Do not spawn subagents or delegate work to other agents unless the user explicitly asks for subagents, delegation, or parallel agent work.
- Use Context7 for current public library, SDK, and framework documentation when unsure.

## Code style

- Prefer current, native patterns and remove redundant, stale, unnecessary, or duplicate code.
- Do not preserve legacy compatibility, adapters, fallback paths, or old config formats unless explicitly requested. Remove superseded code, dead paths, and stale config, tests, and docs together.
- Update affected producers, consumers, contracts, and configuration in the same change.
- Choose the simplest design with a concrete benefit; justify new abstractions, dependencies, and protocols with a current requirement.
- Fix problems at their source. Do not add special cases, exemptions, ignore lists, or workarounds to make a check or a test pass.
- Split code into files by responsibility instead of growing one large file.
- Do not run formatters by hand; the repo's git hooks format on commit.

## Checks

- `devenv tasks run repo:lint` runs static checks; `scripts/check.sh` runs tests. CI runs both inside the same devenv, so local results match CI.
- Put check logic in `scripts/lint.sh` and `scripts/check.sh`; devenv tasks and CI steps only call them.
- When a mistake can recur, prefer a lint rule, type, test, or policy over a new prose rule.
- Mark generated files `linguist-generated` in `.gitattributes`.
- Use the `verify` skill before reporting a change as done, and report check results as they are.

## Tests

- Add tests only when asked or when they protect a distinct behavior, boundary, failure mode, or contract.
- Do not add config-only, getter, no-op, implementation-mirroring, or redundant tests. Remove unnecessary tests in the changed area instead of replacing them one-for-one.

## Comments

- Do not add comments unless explicitly asked, or the logic is a non-obvious invariant, protocol quirk, or security caveat that the code cannot express. Prefix such a comment with `NOTE:`; the shared lint rejects other comments apart from doc comments and tool directives.
- Do not add comments that restate the code, narrate the change, or leave migration/history notes. Prefer clear names, tests, and the commit message.

## Documentation

- Do not create, rewrite, reformat, or “improve” docs, READMEs, or markdown unless the user explicitly asks, or the change alters user-visible behavior / public API / config that those docs already describe.
- When docs must change, edit only the minimal affected sections, and update existing pages instead of adding per-directory READMEs or repeating information maintained elsewhere.
- Put repo-specific agent context in the repo's root `AGENTS.md`, and only what the code, docs and checks do not already say. Do not add it to OpenSpec config or per-repo skills.

## OpenSpec

- Proposals are short and tied to the real repo state: the concrete problem, the expected behavior, explicit non-goals when scope can grow, and any intentional breaking changes.
- Specs describe observable behavior and boundaries, not implementation details.
- Tasks are small, verifiable steps that include removing superseded code and updating affected references.
- Keep change proposals separate from durable docs. When archiving, state unresolved verification gaps.

## Git

- Keep commits small and focused.
