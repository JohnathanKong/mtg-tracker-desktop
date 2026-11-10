#!/usr/bin/env sh
set -eu
cd "$(dirname "$0")/.."
docker build -t mtg-tracker-desktop-builder .
docker run --rm -v "$(pwd):/src" -w /src mtg-tracker-desktop-builder
echo "Linux executable: build/linux/MTGTrackerDesktop"
echo "For the bundled Windows .exe, download the Actions artifact from GitHub."
