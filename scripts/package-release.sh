#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=scripts/lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

for command_name in tar zstd sha256sum jq git awk cp; do
  require_command "$command_name"
done

ROOT=$(repo_root)
OUT_DIR=${OUT_DIR:-$ROOT/out}
SOURCE_ROOT=$OUT_DIR/release-root
LOCK_FILE=$OUT_DIR/package-lock.tsv
BUNDLE_NAME=qt6-toolchain-debian13-amd64
BUNDLE_DIR=$OUT_DIR/$BUNDLE_NAME
ARCHIVE=$OUT_DIR/$BUNDLE_NAME.tar.zst
CHECKSUM=$ARCHIVE.sha256

[[ -d $SOURCE_ROOT/repo ]] || fail 'offline repository has not been built'
[[ -s $LOCK_FILE ]] || fail 'package lock has not been generated'

rm -rf "$BUNDLE_DIR" "$ARCHIVE" "$CHECKSUM"
mkdir -p "$BUNDLE_DIR/manifests" "$BUNDLE_DIR/scripts/lib" "$BUNDLE_DIR/docs"
cp -a "$SOURCE_ROOT/repo" "$BUNDLE_DIR/repo"
cp "$ROOT/manifests/qt6-debian13-packages.txt" "$BUNDLE_DIR/manifests/"
cp "$LOCK_FILE" "$BUNDLE_DIR/package-lock.tsv"
cp "$ROOT/scripts/install-offline.sh" "$ROOT/scripts/verify-installed.sh" "$BUNDLE_DIR/scripts/"
cp "$ROOT/scripts/lib/common.sh" "$BUNDLE_DIR/scripts/lib/"
cp -a "$ROOT/smoke" "$BUNDLE_DIR/smoke"
cp "$ROOT/README.md" "$BUNDLE_DIR/README.md"
cp "$ROOT/docs/RECOVERY.md" "$BUNDLE_DIR/docs/RECOVERY.md"
chmod 0755 "$BUNDLE_DIR/scripts/install-offline.sh" "$BUNDLE_DIR/scripts/verify-installed.sh"

commit_sha=${GITHUB_SHA:-$(git -C "$ROOT" rev-parse HEAD)}
source_date_epoch=${SOURCE_DATE_EPOCH:-$(git -C "$ROOT" show -s --format=%ct "$commit_sha")}
build_time=$(date -u -d "@$source_date_epoch" '+%Y-%m-%dT%H:%M:%SZ')
qt_version=$(awk -F '\t' '$1 == "qt6-base-dev" { print $2; exit }' "$LOCK_FILE")
qtcreator_version=$(awk -F '\t' '$1 == "qtcreator" { print $2; exit }' "$LOCK_FILE")
package_count=$(wc -l < "$LOCK_FILE")

jq -n \
  --arg schema_version '1' \
  --arg target 'debian-13-amd64' \
  --arg commit_sha "$commit_sha" \
  --arg build_time "$build_time" \
  --arg qt_version "$qt_version" \
  --arg qtcreator_version "$qtcreator_version" \
  --argjson source_date_epoch "$source_date_epoch" \
  --argjson package_count "$package_count" \
  '{
    schema_version: $schema_version,
    target: $target,
    commit_sha: $commit_sha,
    source_date_epoch: $source_date_epoch,
    build_time: $build_time,
    qt_version: $qt_version,
    qtcreator_version: $qtcreator_version,
    package_count: $package_count
  }' > "$BUNDLE_DIR/build-metadata.json"

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
