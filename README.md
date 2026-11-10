# MTG Tracker Desktop

A native Windows C++20 application for managing MTG Commander deck profiles.

V0.1 scope: add/edit/delete deck profiles, assign commander names, import artwork, select counters and save locally. No ESP32 connection yet.

## Build via Docker

Requirements: Docker on build machine only.

PowerShell:

    docker build -t mtg-desktop-builder .
    docker run --rm -v "${PWD}:/src" -w /src mtg-desktop-builder sh -c "cmake -S . -B build/windows -G Ninja -DCMAKE_TOOLCHAIN_FILE=cmake/mingw.cmake -DCMAKE_BUILD_TYPE=Release && cmake --build build/windows"

Linux/macOS shell: ./scripts/build.sh

Output: build/windows/MTGTrackerDesktop.exe. Run on Windows without installing a GUI framework, Python, Node, or Docker.

Native Visual Studio alternative:

    cmake -S . -B build/native -G "Visual Studio 17 2022" -A x64
    cmake --build build/native --config Release

## Stored data

Local folder: %LOCALAPPDATA%\MTGTrackerDesktop\
- decks.ini — UTF-16 profile index and enabled stable counter IDs
- images/ — copied artwork for each deck

Backup: copy the entire folder. Deleting a deck does not delete saved image files.

## Design

Win32 + GDI+ and C++20, CMake, MinGW-w64 cross-compiler in Docker, no third-party GUI runtime.

Counter selection is by deck, not locked to the commander card: two decks using the same commander can have different trackers. Poison and rad are selected by default because opposing decks can give them to you.

No network access, telemetry, account, or hardware integration in this milestone.

ESP32 firmware repository: https://github.com/JohnathanKong/mtg-tracker
