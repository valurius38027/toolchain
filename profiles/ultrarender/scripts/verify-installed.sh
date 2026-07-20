#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=profiles/ultrarender/scripts/lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

require_debian13_amd64
for command_name in cmake ninja g++ clang++ ctest qmake6 pkg-config flatc glslangValidator spirv-val xvfb-run vulkaninfo timeout grep find; do
  require_command "$command_name"
done

export LANG=C.UTF-8
export LC_ALL=C.UTF-8

BUNDLE_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
SMOKE_DIR=$BUNDLE_ROOT/smoke
WORK_DIR=${VERIFY_WORK_DIR:-$BUNDLE_ROOT/verification-work}
REPORT=${VERIFICATION_REPORT:-$BUNDLE_ROOT/ultrarender-verification-report.txt}
VULKAN_REPORT=$WORK_DIR/vulkan-summary.txt
LVP_ICD=/usr/share/vulkan/icd.d/lvp_icd.json

[[ -f $LVP_ICD ]] || fail "Lavapipe ICD not found: $LVP_ICD"
[[ -f /usr/include/vulkan/vulkan.h ]] || fail 'Vulkan development header is missing'
[[ -n $(find /usr/include -type f \( -path '*/QtGui/*/QtGui/rhi/qrhi.h' -o -path '*/QtGui/*/QtGui/private/qrhi_p.h' \) -print -quit) ]] || fail 'Qt QRhi header is missing'

rm -rf "$WORK_DIR"
mkdir -p "$WORK_DIR"
: > "$REPORT"
exec > >(tee -a "$REPORT") 2>&1

printf 'UltraRender Debian 13 SDK verification\n'
printf 'UTC: %s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
printf 'Architecture: %s\n' "$(dpkg --print-architecture)"
printf '\n== Versions ==\n'
cmake --version
ninja --version
g++ --version
clang++ --version
printf 'Qt: %s\n' "$(qmake6 -query QT_VERSION)"
printf 'FreeType: %s\n' "$(pkg-config --modversion freetype2)"
printf 'HarfBuzz: %s\n' "$(pkg-config --modversion harfbuzz)"
flatc --version
glslangValidator --version
spirv-val --version

build_and_test() {
  local name=$1
  local compiler=$2
  local build_dir=$WORK_DIR/$name

  printf '\n== Configure, build and test: %s ==\n' "$name"
  cmake \
    -S "$SMOKE_DIR" \
    -B "$build_dir" \
    -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_COMPILER="$compiler"
  cmake --build "$build_dir" --parallel 2
  ctest --test-dir "$build_dir" --output-on-failure
  "$build_dir/ultrarender_sdk_smoke"
}

build_and_test gcc g++
build_and_test clang clang++

printf '\n== Lavapipe Vulkan device ==\n'
env \
  VK_DRIVER_FILES="$LVP_ICD" \
  VK_ICD_FILENAMES="$LVP_ICD" \
  xvfb-run -a timeout 30s vulkaninfo --summary | tee "$VULKAN_REPORT"
grep -Eiq 'PHYSICAL_DEVICE_TYPE_CPU|llvmpipe|lavapipe' "$VULKAN_REPORT" || fail 'Lavapipe CPU Vulkan device was not enumerated'

printf '\nVERIFICATION_RESULT=PASS\n'
