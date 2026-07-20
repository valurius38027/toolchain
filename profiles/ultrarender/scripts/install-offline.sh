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

log 'verifying every bundled package file before installation'
while IFS=$'\t' read -r package_name package_version package_arch filename expected_sha256; do
  [[ -n $package_name && -n $package_version && -n $package_arch && -n $filename && -n $expected_sha256 ]] || fail 'malformed package lock row'
  deb_file=$REPO_DIR/pool/$filename
  [[ -s $deb_file ]] || fail "locked package file is missing: $filename"
  actual_sha256=$(sha256sum "$deb_file" | awk '{ print $1 }')
  [[ $actual_sha256 == "$expected_sha256" ]] || fail "checksum mismatch for package file: $filename"
done < "$LOCK_FILE"

for package_name in "${PACKAGES[@]}"; do
  awk -F '\t' -v requested="$package_name" '$1 == requested { found = 1; exit } END { exit !found }' "$LOCK_FILE" \
    || fail "requested package is absent from the package lock: $package_name"
done

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

log "installing ${#PACKAGES[@]} required toolchain packages from the bundled repository"
apt-get "${APT_OPTIONS[@]}" --no-install-recommends install -y "${PACKAGES[@]}"

log 'verifying required toolchain package versions and architectures against the lock'
for package_name in "${PACKAGES[@]}"; do
  lock_row=$(awk -F '\t' -v requested="$package_name" '$1 == requested { print; exit }' "$LOCK_FILE")
  [[ -n $lock_row ]] || fail "requested package has no lock row: $package_name"
  IFS=$'\t' read -r _locked_name expected_version expected_arch _filename _sha256 <<< "$lock_row"

  installed_row=$(dpkg-query -W -f='${Status}\t${Version}\t${Architecture}' "$package_name" 2>/dev/null) \
    || fail "required package is not installed: $package_name"
  IFS=$'\t' read -r installed_status installed_version installed_arch <<< "$installed_row"

  [[ $installed_status == 'install ok installed' ]] || fail "required package is not fully installed: $package_name ($installed_status)"
  [[ $installed_version == "$expected_version" ]] || fail "version mismatch for $package_name: expected $expected_version, got $installed_version"
  [[ $installed_arch == "$expected_arch" ]] || fail "architecture mismatch for $package_name: expected $expected_arch, got $installed_arch"
done

log 'offline installation, bundle integrity, and required-package verification completed'
