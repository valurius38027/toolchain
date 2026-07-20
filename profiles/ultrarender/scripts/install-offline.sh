#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=profiles/ultrarender/scripts/lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

require_root
require_debian13_amd64
for command_name in apt-get dpkg-query sha256sum awk mktemp; do
  require_command "$command_name"
done

BUNDLE_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
MANIFEST=$BUNDLE_ROOT/profile/packages.txt
LOCK_FILE=$BUNDLE_ROOT/ultrarender-package-lock.tsv
REPO_DIR=$BUNDLE_ROOT/repo

[[ -f $REPO_DIR/Packages.gz ]] || fail "local APT index not found: $REPO_DIR/Packages.gz"
[[ -s $LOCK_FILE ]] || fail "package lock not found: $LOCK_FILE"
mapfile -t PACKAGES < <(manifest_packages "$MANIFEST")
((${#PACKAGES[@]} > 0)) || fail 'package manifest is empty'

log 'verifying every bundled package before installation'
while IFS=$'\t' read -r package_name package_version package_arch filename expected_sha256; do
  [[ -n $package_name && -n $package_version && -n $package_arch && -n $filename && -n $expected_sha256 ]] || fail 'malformed package lock row'
  deb_file=$REPO_DIR/pool/$filename
  [[ -s $deb_file ]] || fail "locked package file is missing: $filename"
  actual_sha256=$(sha256sum "$deb_file" | awk '{ print $1 }')
  [[ $actual_sha256 == "$expected_sha256" ]] || fail "checksum mismatch for package file: $filename"
done < "$LOCK_FILE"

SOURCE_FILE=$(mktemp)
trap 'rm -f "$SOURCE_FILE"' EXIT
printf 'deb [trusted=yes] file:%s ./\n' "$REPO_DIR" > "$SOURCE_FILE"

APT_OPTIONS=(
  -o "Dir::Etc::sourcelist=$SOURCE_FILE"
  -o 'Dir::Etc::sourceparts=-'
  -o 'APT::Get::List-Cleanup=0'
  -o 'Acquire::Languages=none'
  -o 'Acquire::Retries=0'
)

export DEBIAN_FRONTEND=noninteractive
log 'updating APT exclusively from the bundled repository'
apt-get "${APT_OPTIONS[@]}" update

log "installing ${#PACKAGES[@]} requested packages from the bundled repository"
apt-get "${APT_OPTIONS[@]}" --no-install-recommends install -y "${PACKAGES[@]}"

log 'verifying installed package versions and architectures against the lock'
while IFS=$'\t' read -r package_name package_version package_arch _filename _sha256; do
  installed_version=$(dpkg-query -W -f='${Version}' "$package_name" 2>/dev/null) || fail "locked package is not installed: $package_name"
  installed_arch=$(dpkg-query -W -f='${Architecture}' "$package_name" 2>/dev/null) || fail "cannot query architecture: $package_name"
  [[ $installed_version == "$package_version" ]] || fail "version mismatch for $package_name: expected $package_version, got $installed_version"
  [[ $installed_arch == "$package_arch" ]] || fail "architecture mismatch for $package_name: expected $package_arch, got $installed_arch"
done < "$LOCK_FILE"

log 'offline installation and package-lock verification completed'
