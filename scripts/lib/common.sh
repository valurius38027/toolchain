#!/usr/bin/env bash
set -Eeuo pipefail

log() {
  printf '[qt6-toolchain] %s\n' "$*" >&2
}

fail() {
  printf '[qt6-toolchain] ERROR: %s\n' "$*" >&2
  exit 1
}

require_root() {
  if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
    fail 'this operation must run as root'
  fi
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || fail "required command not found: $1"
}

repo_root() {
  cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd
}

manifest_packages() {
  local manifest=$1
  [[ -f $manifest ]] || fail "package manifest not found: $manifest"
  awk '
    { sub(/[[:space:]]*#.*/, "") }
    NF { print $1 }
  ' "$manifest"
}

assert_unique_lines() {
  local file=$1
  local duplicates
  duplicates=$(sort "$file" | uniq -d || true)
  [[ -z $duplicates ]] || fail "duplicate entries detected in $file: $duplicates"
}

sha256_file() {
  local file=$1
  sha256sum "$file" | awk '{print $1}'
}
