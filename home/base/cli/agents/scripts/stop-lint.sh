input="$(cat)"
[[ "$(jq -r '.stop_hook_active // false' <<<"$input")" == true ]] && exit 0
cd "$(jq -r '.cwd' <<<"$input")" 2>/dev/null || exit 0
root="$(git rev-parse --show-toplevel 2>/dev/null)" || exit 0
cd "$root"
grep -qs devenv-modules devenv.yaml || exit 0
[[ -n "$(git status --porcelain)" ]] || exit 0
if ! output="$(devenv tasks run repo:lint 2>&1)"; then
  printf 'repo:lint failed. Fix these before finishing:\n%s\n' "$(tail -n 80 <<<"$output")" >&2
  exit 2
fi
