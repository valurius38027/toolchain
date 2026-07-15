#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=scripts/lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

require_root
for command_name in apt-get dpkg-query awk mktemp; do
  require_command "$command_name"
done

BUNDLE_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
MANIFEST=$BUNDLE_ROOT/manifests/qt6-debian13-packages.txt
LOCK_FILE=$BUNDLE_ROOT/package-lock.tsv
REPO_DIR=$BUNDLE_ROOT/repo

[[ -f $REPO_DIR/Packages.gz ]] || fail "local APT index not found: $REPO_DIR/Packages.gz"
[[ -s $LOCK_FILE ]] || fail "package lock not found: $LOCK_FILE"
mapfile -t PACKAGES < <(manifest_packages "$MANIFEST")
((${#PACKAGES[@]} > 0)) || fail 'package manifest is empty'

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
log 'updating APT exclusively from bundled repository'
apt-get "${APT_OPTIONS[@]}" update

log "installing ${#PACKAGES[@]} requested packages from bundled repository"
apt-get "${APT_OPTIONS[@]}" --no-install-recommends install -y "${PACKAGES[@]}"

log 'verifying installed package versions against package lock'
while IFS=$'\t' read -r package_name package_version package_arch _filename _sha256; do
  installed_version=$(dpkg-query -W -f='${Version}' "$package_name" 2>/dev/null) || fail "locked package is not installed: $package_name"
  installed_arch=$(dpkg-query -W -f='${Architecture}' "$package_name" 2>/dev/null) || fail "cannot query architecture: $package_name"
  [[ $installed_version == "$package_version" ]] || fail "version mismatch for $package_name: expected $package_version, got $installed_version"
  [[ $installed_arch == "$package_arch" ]] || fail "architecture mismatch for $package_name: expected $package_arch, got $installed_arch"
done < "$LOCK_FILE"

log 'offline installation and package lock verification completed'
