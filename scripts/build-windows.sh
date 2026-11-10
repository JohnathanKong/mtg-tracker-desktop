#!/usr/bin/env bash
set -euo pipefail

# Executed inside the Linux Docker image containing Windows Qt + MinGW tools.
# No host-side C++/Qt installations are required.
cd /src

BUILD_DIR="build/docker-windows"
DIST_DIR="dist/windows"

echo "==> Building Windows x64 executable with Qt/MinGW in Docker"
# Never reuse the prior Linux or MSVC CMake caches.
cmake -S . -B "$BUILD_DIR" -G Ninja -DCMAKE_BUILD_TYPE=Release
cmake --build "$BUILD_DIR" --config Release --parallel 2

APP="$BUILD_DIR/MTGTrackerDesktop.exe"
if [[ ! -s "$APP" ]]; then
  echo "ERROR: Missing Windows executable: $APP" >&2
  exit 1
fi
# Windows executable headers begin with MZ. Fail if a Linux ELF was produced.
HEADER="$(od -An -tx1 -N2 "$APP" | tr -d ' \n')"
if [[ "$HEADER" != "4d5a" ]]; then
  echo "ERROR: Output is not a Windows PE executable (MZ header missing)." >&2
  exit 1
fi

echo "==> Packaging portable Windows Qt deployment"
mkdir -p "$DIST_DIR"
cp -f "$APP" "$DIST_DIR/MTGTrackerDesktop.exe"

# windeployqt runs under Wine in this image. --qmldir is mandatory for a
# QML/Qt Quick app, otherwise the required runtime QML plugins are omitted.
windeployqt --release --compiler-runtime --no-translations \
  --qmldir qml --dir "$DIST_DIR" "$DIST_DIR/MTGTrackerDesktop.exe"

# Cross-builds sometimes omit MinGW runtime DLLs. Copy the exact toolchain's
# runtimes, never DLLs from an unrelated system compiler.
MINGW_BIN="/opt/Tools/mingw1310_64/bin"
for runtime in libgcc_s_seh-1.dll libstdc++-6.dll libwinpthread-1.dll; do
  if [[ -f "$MINGW_BIN/$runtime" ]]; then
    cp -f "$MINGW_BIN/$runtime" "$DIST_DIR/"
  elif [[ ! -f "$DIST_DIR/$runtime" ]]; then
    echo "ERROR: Missing MinGW runtime $runtime" >&2
    exit 1
  fi
done

for required in Qt6Core.dll Qt6Gui.dll Qt6Qml.dll Qt6Quick.dll \
                Qt6QuickControls2.dll platforms/qwindows.dll; do
  if [[ ! -s "$DIST_DIR/$required" ]]; then
    echo "ERROR: Qt deployment missing $required" >&2
    exit 1
  fi
done

echo "==> Windows build ready: $DIST_DIR/MTGTrackerDesktop.exe"
echo "    Keep all DLLs, QML modules and plugin folders together."
