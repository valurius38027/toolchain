#!/usr/bin/env bash
set -Eeuo pipefail

log() {
  printf '[ultrarender-sdk] %s\n' "$*" >&2
}

fail() {
  printf '[ultrarender-sdk] ERROR: %s\n' "$*" >&2
  exit 1
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || fail "required command not found: $1"
}

require_root() {
  if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
    fail 'this operation must run as root'
  fi
}

profile_root() {
  cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd
}

repo_root() {
  cd "$(profile_root)/../.." && pwd
}

manifest_packages() {
  local manifest=$1
  [[ -f $manifest ]] || fail "package manifest not found: $manifest"
  awk '
    { sub(/[[:space:]]*#.*/, "") }
    NF { print $1 }
  ' "$manifest"
}

read_profile_version() {
  local version_file=${1:-$(profile_root)/VERSION}
  [[ -s $version_file ]] || fail "version file not found or empty: $version_file"
  local version
  version=$(tr -d '[:space:]' < "$version_file")
  [[ $version =~ ^[0-9]{4}\.[0-9]{2}\.[0-9]{2}\.[0-9]+$ ]] || fail "invalid profile version: $version"
  printf '%s\n' "$version"
}

assert_unique_lines() {
  local file=$1
  local duplicates
  duplicates=$(sort "$file" | uniq -d || true)
  [[ -z $duplicates ]] || fail "duplicate entries detected in $file: $duplicates"
}

sha256_file() {
  local file=$1
  sha256sum "$file" | awk '{ print $1 }'
}

require_debian13_amd64() {
  [[ -r /etc/os-release ]] || fail '/etc/os-release is unavailable'
  # shellcheck disable=SC1091
  source /etc/os-release
  [[ ${ID:-} == debian ]] || fail "unsupported distribution: ${ID:-unknown}"
  [[ ${VERSION_ID:-} == 13 ]] || fail "unsupported Debian version: ${VERSION_ID:-unknown}"
  [[ $(dpkg --print-architecture) == amd64 ]] || fail "unsupported architecture: $(dpkg --print-architecture)"
}
