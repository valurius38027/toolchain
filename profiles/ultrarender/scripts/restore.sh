#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=profiles/ultrarender/scripts/lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

require_root
require_debian13_amd64

REPOSITORY=${ULTRARENDER_SDK_REPOSITORY:-valurius38027/toolchain}
TAG_PREFIX=ultrarender-sdk-debian13-v
BUNDLE_NAME=ultrarender-dev-sdk-debian13-amd64
ARCHIVE=$BUNDLE_NAME.tar.zst
CHECKSUM=$ARCHIVE.sha256
LOCK_ASSET=ultrarender-package-lock.tsv
METADATA_ASSET=ultrarender-build-metadata.json
REPORT_ASSET=ultrarender-verification-report.txt
CACHE_DIR=${ULTRARENDER_SDK_CACHE:-/var/cache/ultrarender-sdk}
SELECTOR=latest
FORCE=false
DOWNLOAD_ONLY=false

usage() {
  cat <<'USAGE'
Usage: sudo bash restore.sh [latest|RELEASE_TAG] [--force] [--download-only] [--cache-dir PATH]

Examples:
  sudo bash restore.sh latest
  sudo bash restore.sh ultrarender-sdk-debian13-v2026.07.20.1
  sudo bash restore.sh latest --force
USAGE
}

if (($# > 0)) && [[ $1 != --* ]]; then
  SELECTOR=$1
  shift
fi

while (($# > 0)); do
  case $1 in
    --force)
      FORCE=true
      ;;
    --download-only)
      DOWNLOAD_ONLY=true
      ;;
    --cache-dir)
      shift
      (($# > 0)) || fail '--cache-dir requires a path'
      CACHE_DIR=$1
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      fail "unknown argument: $1"
      ;;
  esac
  shift
done

bootstrap_download_tools() {
  local packages=()
  command -v curl >/dev/null 2>&1 || packages+=(curl)
  command -v jq >/dev/null 2>&1 || packages+=(jq)
  command -v zstd >/dev/null 2>&1 || packages+=(zstd)
  command -v ca-certificates >/dev/null 2>&1 || packages+=(ca-certificates)
  if ((${#packages[@]} > 0)); then
    log "installing restore bootstrap tools: ${packages[*]}"
    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "${packages[@]}"
  fi
  for command_name in curl jq zstd tar sha256sum; do
    require_command "$command_name"
  done
}

bootstrap_download_tools
mkdir -p "$CACHE_DIR"

api_get() {
  local url=$1
  local headers=(-H 'Accept: application/vnd.github+json' -H 'X-GitHub-Api-Version: 2022-11-28')
  if [[ -n ${GITHUB_TOKEN:-} ]]; then
    headers+=(-H "Authorization: Bearer $GITHUB_TOKEN")
  fi
  curl -fsSL "${headers[@]}" "$url"
}

resolve_tag_with_api() {
  local selector=$1
  local response
  if [[ $selector == latest ]]; then
    response=$(api_get "https://api.github.com/repos/$REPOSITORY/releases/latest")
  else
    response=$(api_get "https://api.github.com/repos/$REPOSITORY/releases/tags/$selector")
  fi
  jq -er '.tag_name' <<<"$response"
}

resolve_tag() {
  local selector=$1
  local tag
  if command -v gh >/dev/null 2>&1; then
    if [[ $selector == latest ]]; then
      tag=$(gh release view --repo "$REPOSITORY" --json tagName --jq '.tagName')
    else
      tag=$(gh release view "$selector" --repo "$REPOSITORY" --json tagName --jq '.tagName')
    fi
  else
    tag=$(resolve_tag_with_api "$selector")
  fi
  [[ $tag =~ ^ultrarender-sdk-debian13-v[0-9]{4}\.[0-9]{2}\.[0-9]{2}\.[0-9]+$ ]] || fail "invalid UltraRender SDK release tag: $tag"
  printf '%s\n' "$tag"
}

TAG=$(resolve_tag "$SELECTOR")
VERSION=${TAG#"$TAG_PREFIX"}
TAG_DIR=$CACHE_DIR/$TAG
ASSET_DIR=$TAG_DIR/assets
EXTRACT_DIR=$TAG_DIR/extracted
BUNDLE_ROOT=$EXTRACT_DIR/$BUNDLE_NAME
LOCAL_REPORT=$TAG_DIR/local-verification-report.txt

if [[ $FORCE == true ]]; then
  log "discarding cached release: $TAG_DIR"
  rm -rf "$TAG_DIR"
fi
mkdir -p "$ASSET_DIR"

required_assets=("$ARCHIVE" "$CHECKSUM" "$LOCK_ASSET" "$METADATA_ASSET" "$REPORT_ASSET")
assets_are_valid() {
  local asset
  for asset in "${required_assets[@]}"; do
    [[ -s $ASSET_DIR/$asset ]] || return 1
  done
  (cd "$ASSET_DIR" && sha256sum -c "$CHECKSUM") >/dev/null 2>&1
}

fetch_assets_with_api() {
  local tag=$1
  local response asset url
  response=$(api_get "https://api.github.com/repos/$REPOSITORY/releases/tags/$tag")
  for asset in "${required_assets[@]}"; do
    url=$(jq -er --arg name "$asset" '.assets[] | select(.name == $name) | .browser_download_url' <<<"$response")
    log "downloading $asset"
    curl -fL --retry 3 --retry-delay 2 -o "$ASSET_DIR/$asset.part" "$url"
    mv "$ASSET_DIR/$asset.part" "$ASSET_DIR/$asset"
  done
}

if assets_are_valid; then
  log "using cached and checksum-verified assets for $TAG"
else
  rm -f "$ASSET_DIR"/*
  if command -v gh >/dev/null 2>&1; then
    log "downloading release assets with GitHub CLI: $TAG"
    gh release download "$TAG" --repo "$REPOSITORY" --dir "$ASSET_DIR"
  else
    fetch_assets_with_api "$TAG"
  fi
  for asset in "${required_assets[@]}"; do
    [[ -s $ASSET_DIR/$asset ]] || fail "release asset is missing or empty: $asset"
  done
  (cd "$ASSET_DIR" && sha256sum -c "$CHECKSUM")
fi

jq -e \
  --arg version "$VERSION" \
  '.profile == "ultrarender" and .profile_version == $version and .target == "debian-13-amd64" and .package_count > 0' \
  "$ASSET_DIR/$METADATA_ASSET" >/dev/null || fail 'release metadata does not match the selected tag or platform'
grep -qx 'VERIFICATION_RESULT=PASS' "$ASSET_DIR/$REPORT_ASSET" || fail 'published release verification report is not successful'

rm -rf "$EXTRACT_DIR"
mkdir -p "$EXTRACT_DIR"
tar --zstd -xf "$ASSET_DIR/$ARCHIVE" -C "$EXTRACT_DIR"
[[ -x $BUNDLE_ROOT/scripts/install-offline.sh ]] || fail 'archive does not contain the offline installer'
[[ -x $BUNDLE_ROOT/scripts/verify-installed.sh ]] || fail 'archive does not contain the verification script'

if [[ $DOWNLOAD_ONLY == true ]]; then
  log "release downloaded, verified and extracted at $BUNDLE_ROOT"
  exit 0
fi

bash "$BUNDLE_ROOT/scripts/install-offline.sh"
VERIFICATION_REPORT=$LOCAL_REPORT \
VERIFY_WORK_DIR=$TAG_DIR/verification-work \
  bash "$BUNDLE_ROOT/scripts/verify-installed.sh"
grep -qx 'VERIFICATION_RESULT=PASS' "$LOCAL_REPORT" || fail 'local SDK verification did not pass'

printf '%s\n' "$TAG" > "$CACHE_DIR/current"
log "UltraRender SDK $TAG is installed and verified"
