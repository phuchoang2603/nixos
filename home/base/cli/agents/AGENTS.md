- Prefer entering a repo's Nix devenv before work (`devenv allow`, `devenv shell`, or the project’s documented equivalent) whenever a devenv/flake/direnv setup exists.
- If devenv cannot be used, say so briefly and continue with the closest available tools.
- Use the Context7 MCP for current library/framework docs and best practices instead of relying on training data, whenever the task involves a public API, SDK, or framework.

## Comments

- Do not add comments unless explicitly asked, or the logic is a non-obvious invariant, protocol quirk, or security caveat that the code cannot express.
- Do not add comments that restate the code, narrate the change (`// updated for …`, `// removed …`), or leave migration/history notes. Prefer clear names, tests, and the commit message.
- Keep existing comments, docstrings, and license headers unless the change makes them inaccurate.

## Documentation

- Do not create, rewrite, reformat, or “improve” docs, READMEs, or markdown unless the user explicitly asks, or the change alters user-visible behavior / public API / config that those docs already describe.
- When docs must change, edit only the minimal affected sections; do not restyle or regenerate surrounding content.
