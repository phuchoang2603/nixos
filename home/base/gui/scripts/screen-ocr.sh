capture_dir="$(mktemp -d)"
trap 'rm -rf "$capture_dir"' EXIT

if [[ "$(uname -s)" == Darwin ]]; then
  if ! /usr/sbin/screencapture -i -s "$capture_dir/capture.png"; then
    exit 0
  fi
else
  if ! region="$(slurp)"; then
    exit 0
  fi
  [[ -n "$region" ]] || exit 0
  grim -g "$region" "$capture_dir/capture.png"
fi

[[ -s "$capture_dir/capture.png" ]] || exit 0
tesseract "$capture_dir/capture.png" "$capture_dir/text" -l eng
[[ -s "$capture_dir/text.txt" ]] || exit 0

if [[ "$(uname -s)" == Darwin ]]; then
  /usr/bin/pbcopy < "$capture_dir/text.txt"
else
  wl-copy --type 'text/plain;charset=utf-8' < "$capture_dir/text.txt"
fi
