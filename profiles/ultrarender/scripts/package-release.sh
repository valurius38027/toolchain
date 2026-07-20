#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=profiles/ultrarender/scripts/lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

for command_name in tar zstd sha256sum jq awk cp date git; do
  require_command "$command_name"
done

PROFILE_ROOT=$(profile_root)
ROOT=$(repo_root)
OUT_DIR=${OUT_DIR:-$ROOT/out/ultrarender}
SOURCE_ROOT=$OUT_DIR/release-root
LOCK_FILE=$OUT_DIR/ultrarender-package-lock.tsv
BUNDLE_NAME=ultrarender-dev-sdk-debian13-amd64
BUNDLE_DIR=$OUT_DIR/$BUNDLE_NAME
ARCHIVE=$OUT_DIR/$BUNDLE_NAME.tar.zst
CHECKSUM=$ARCHIVE.sha256
METADATA=$OUT_DIR/ultrarender-build-metadata.json
VERSION=$(read_profile_version "$PROFILE_ROOT/VERSION")

[[ -d $SOURCE_ROOT/repo ]] || fail 'offline repository has not been built'
[[ -s $LOCK_FILE ]] || fail 'package lock has not been generated'

commit_sha=${GITHUB_SHA:-$(git -C "$ROOT" rev-parse HEAD)}
source_date_epoch=${SOURCE_DATE_EPOCH:-$(git -C "$ROOT" show -s --format=%ct "$commit_sha")}
[[ $commit_sha =~ ^[0-9a-f]{40}$ ]] || fail "invalid source commit SHA: $commit_sha"
[[ $source_date_epoch =~ ^[0-9]+$ ]] || fail "invalid SOURCE_DATE_EPOCH: $source_date_epoch"

rm -rf "$BUNDLE_DIR" "$ARCHIVE" "$CHECKSUM" "$METADATA"
mkdir -p "$BUNDLE_DIR/profile" "$BUNDLE_DIR/scripts/lib" "$BUNDLE_DIR/docs"
cp -a "$SOURCE_ROOT/repo" "$BUNDLE_DIR/repo"
cp "$PROFILE_ROOT/packages.txt" "$BUNDLE_DIR/profile/packages.txt"
cp "$PROFILE_ROOT/VERSION" "$BUNDLE_DIR/profile/VERSION"
cp "$LOCK_FILE" "$BUNDLE_DIR/ultrarender-package-lock.tsv"
cp "$PROFILE_ROOT/scripts/install-offline.sh" "$PROFILE_ROOT/scripts/verify-installed.sh" "$BUNDLE_DIR/scripts/"
cp "$PROFILE_ROOT/scripts/lib/common.sh" "$BUNDLE_DIR/scripts/lib/"
cp -a "$PROFILE_ROOT/smoke" "$BUNDLE_DIR/smoke"
cp "$PROFILE_ROOT/README.md" "$BUNDLE_DIR/README.md"
chmod 0755 "$BUNDLE_DIR/scripts/install-offline.sh" "$BUNDLE_DIR/scripts/verify-installed.sh"

build_time=$(date -u -d "@$source_date_epoch" '+%Y-%m-%dT%H:%M:%SZ')
qt_version=$(awk -F '\t' '$1 == "qt6-base-dev" { print $2; exit }' "$LOCK_FILE")
qt_private_version=$(awk -F '\t' '$1 == "qt6-base-private-dev" { print $2; exit }' "$LOCK_FILE")
vulkan_version=$(awk -F '\t' '$1 == "libvulkan-dev" { print $2; exit }' "$LOCK_FILE")
package_count=$(wc -l < "$LOCK_FILE")

jq -n \
  --arg schema_version '1' \
  --arg profile 'ultrarender' \
  --arg profile_version "$VERSION" \
  --arg target 'debian-13-amd64' \
  --arg commit_sha "$commit_sha" \
  --arg build_time "$build_time" \
  --arg qt_version "$qt_version" \
  --arg qt_private_version "$qt_private_version" \
  --arg vulkan_version "$vulkan_version" \
  --argjson source_date_epoch "$source_date_epoch" \
  --argjson package_count "$package_count" \
  '{
    schema_version: $schema_version,
    profile: $profile,
    profile_version: $profile_version,
    target: $target,
    commit_sha: $commit_sha,
    source_date_epoch: $source_date_epoch,
    build_time: $build_time,
    qt_version: $qt_version,
    qt_private_version: $qt_private_version,
    vulkan_version: $vulkan_version,
    package_count: $package_count
  }' > "$METADATA"
cp "$METADATA" "$BUNDLE_DIR/ultrarender-build-metadata.json"

(
  cd "$OUT_DIR"
  tar \
    --sort=name \
    --mtime="@$source_date_epoch" \
    --clamp-mtime \
    --owner=0 \
    --group=0 \
    --numeric-owner \
    --format=posix \
    --pax-option=delete=atime,delete=ctime \
    -cf - "$BUNDLE_NAME" | zstd -15 -T0 -q -o "$ARCHIVE"
)

zstd --test -q "$ARCHIVE"
(
  cd "$OUT_DIR"
  sha256sum "$(basename "$ARCHIVE")" > "$(basename "$CHECKSUM")"
  sha256sum -c "$(basename "$CHECKSUM")"
)

log "created release archive: $ARCHIVE"
