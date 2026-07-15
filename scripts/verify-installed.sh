#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=scripts/lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

for command_name in cmake ninja g++ clang++ ctest xvfb-run timeout glxinfo qtcreator; do
  require_command "$command_name"
done

BUNDLE_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
SMOKE_DIR=$BUNDLE_ROOT/smoke
WORK_DIR=${VERIFY_WORK_DIR:-$BUNDLE_ROOT/verification-work}
REPORT=${VERIFICATION_REPORT:-$BUNDLE_ROOT/verification-report.txt}

QMLLINT=$(command -v qmllint || true)
if [[ -z $QMLLINT && -x /usr/lib/qt6/bin/qmllint ]]; then
  QMLLINT=/usr/lib/qt6/bin/qmllint
fi
[[ -n $QMLLINT ]] || fail 'qmllint was not found'

rm -rf "$WORK_DIR"
mkdir -p "$WORK_DIR"
: > "$REPORT"
exec > >(tee -a "$REPORT") 2>&1

printf 'Qt 6 Debian 13 toolchain verification\n'
printf 'UTC: %s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
printf 'Architecture: %s\n' "$(dpkg --print-architecture)"
printf '\n== Versions ==\n'
cmake --version
ninja --version
g++ --version
clang++ --version
"$QMLLINT" --version
qtcreator -version

build_and_test() {
  local name=$1
  local compiler=$2
  local build_dir=$WORK_DIR/$name
  printf '\n== Configure and build: %s ==\n' "$name"
  cmake \
    -S "$SMOKE_DIR" \
    -B "$build_dir" \
    -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_COMPILER="$compiler"
  cmake --build "$build_dir" --parallel 2
  ctest --test-dir "$build_dir" --output-on-failure
}

build_and_test gcc g++
build_and_test clang clang++

printf '\n== QML lint ==\n'
"$QMLLINT" -I "$SMOKE_DIR/qml" \
  "$SMOKE_DIR/qml/Main.qml" \
  "$SMOKE_DIR/qml/Quick3DScene.qml"

APP=$WORK_DIR/gcc/qt6_toolchain_smoke
[[ -x $APP ]] || fail "smoke executable was not produced: $APP"

printf '\n== OpenGL software renderer ==\n'
xvfb-run -a env LIBGL_ALWAYS_SOFTWARE=1 glxinfo -B

printf '\n== Widgets startup ==\n'
timeout 20s xvfb-run -a env \
  LIBGL_ALWAYS_SOFTWARE=1 \
  QT_OPENGL=software \
  "$APP"

printf '\n== QML and Quick 3D startup ==\n'
timeout 25s xvfb-run -a env \
  LIBGL_ALWAYS_SOFTWARE=1 \
  QT_OPENGL=software \
  QSG_RHI_BACKEND=opengl \
  "$APP" --qml

printf '\n== Qt Creator plugin and platform startup ==\n'
timeout 30s xvfb-run -a env \
  LIBGL_ALWAYS_SOFTWARE=1 \
  QT_OPENGL=software \
  qtcreator -version

printf '\nVERIFICATION_RESULT=PASS\n'
