#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=profiles/ultrarender/scripts/lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

require_root
require_debian13_amd64
for command_name in apt-get apt-cache dpkg-deb dpkg-scanpackages gzip sha256sum awk sort; do
  require_command "$command_name"
done

PROFILE_ROOT=$(profile_root)
ROOT=$(repo_root)
MANIFEST=${MANIFEST:-$PROFILE_ROOT/packages.txt}
OUT_DIR=${OUT_DIR:-$ROOT/out/ultrarender}
RELEASE_ROOT=$OUT_DIR/release-root
REPO_DIR=$RELEASE_ROOT/repo
POOL_DIR=$REPO_DIR/pool
LOCK_FILE=$OUT_DIR/ultrarender-package-lock.tsv
REQUESTED_FILE=$OUT_DIR/requested-packages.txt
EMPTY_STATUS=$OUT_DIR/empty-dpkg-status
DEB_LIST=$OUT_DIR/deb-files.list0

rm -rf "$RELEASE_ROOT" "$OUT_DIR/apt-cache" "$LOCK_FILE" "$REQUESTED_FILE" "$EMPTY_STATUS" "$DEB_LIST"
mkdir -p "$POOL_DIR/partial" "$OUT_DIR/apt-cache/partial"
: > "$EMPTY_STATUS"

mapfile -t PACKAGES < <(manifest_packages "$MANIFEST")
((${#PACKAGES[@]} > 0)) || fail 'package manifest is empty'
printf '%s\n' "${PACKAGES[@]}" > "$REQUESTED_FILE"
assert_unique_lines "$REQUESTED_FILE"

log "validating ${#PACKAGES[@]} requested packages"
apt-get update
for package_name in "${PACKAGES[@]}"; do
  apt-cache show "$package_name" >/dev/null 2>&1 || fail "package is unavailable in Debian 13 repositories: $package_name"
done

log 'resolving dependency closure against an empty dpkg state'
apt-get \
  -o "Dir::State::status=$EMPTY_STATUS" \
  -o "Dir::Cache::archives=$POOL_DIR" \
  -o 'APT::Keep-Downloaded-Packages=true' \
  -o 'Acquire::Languages=none' \
  --download-only \
  --no-install-recommends \
  install -y "${PACKAGES[@]}"

find "$POOL_DIR" -maxdepth 1 -type f -name '*.deb' -print0 | sort -z > "$DEB_LIST"
[[ -s $DEB_LIST ]] || fail 'APT produced no .deb files'

: > "$LOCK_FILE"
while IFS= read -r -d '' deb_file; do
  dpkg-deb --info "$deb_file" >/dev/null
  package_name=$(dpkg-deb -f "$deb_file" Package)
  package_version=$(dpkg-deb -f "$deb_file" Version)
  package_arch=$(dpkg-deb -f "$deb_file" Architecture)
  case "$package_arch" in
    amd64|all) ;;
    *) fail "unexpected package architecture $package_arch in $deb_file" ;;
  esac
  printf '%s\t%s\t%s\t%s\t%s\n' \
    "$package_name" \
    "$package_version" \
    "$package_arch" \
    "$(basename "$deb_file")" \
    "$(sha256_file "$deb_file")" >> "$LOCK_FILE"
done < "$DEB_LIST"

sort -o "$LOCK_FILE" "$LOCK_FILE"
if cut -f1-3 "$LOCK_FILE" | uniq -d | grep -q .; then
  fail 'duplicate Package/Version/Architecture identities found in downloaded closure'
fi

log 'generating local APT repository index'
(
  cd "$REPO_DIR"
  dpkg-scanpackages --multiversion pool /dev/null > Packages
  gzip -n -9 -c Packages > Packages.gz
)

package_count=$(wc -l < "$LOCK_FILE")
[[ $package_count -gt 0 ]] || fail 'package lock is empty'
log "offline repository contains $package_count package files"
