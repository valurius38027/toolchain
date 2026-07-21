#!/usr/bin/env bash
set -euo pipefail

# This script is the canonical reconstruction entry point for the vault CI and operators.
root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
bundle_name=UltraRenderStudio-production-bootstrap-v1.bundle
bundle="$root/$bundle_name"
sidecar="$root/$bundle_name.sha256"

command -v base64 >/dev/null
command -v sha256sum >/dev/null
command -v git >/dev/null

test -d "$root/encoded"
test -s "$sidecar"

mapfile -t parts < <(find "$root/encoded" -maxdepth 1 -type f -name 'part-*' -print | sort)
test "${#parts[@]}" -eq 9

cat "${parts[@]}" | base64 --decode > "$bundle.tmp"
mv "$bundle.tmp" "$bundle"

(
  cd "$root"
  sha256sum -c "$bundle_name.sha256"
)
git bundle verify "$bundle"

printf 'VAULT_BUNDLE_RESULT=PASS\nBUNDLE=%s\n' "$bundle"
