#!/usr/bin/env sh
set -eu
cd "$(dirname "$0")/.."

docker build -t mtg-tracker-desktop-builder .
docker run --rm -v "$(pwd):/src" -w /src mtg-tracker-desktop-builder

echo "Portable Windows application: dist/windows/MTGTrackerDesktop.exe"
echo "Keep the entire dist/windows directory; Qt DLLs and plugins are required."
