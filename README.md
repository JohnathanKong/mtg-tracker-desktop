# MTG Tracker Desktop

**MTG Tracker Desktop v0.2** — a cinematic, Windows-first Commander deck library built in native **C++20 + Qt Quick/QML**.

- Grid of illustrated Commander deck cards (artwork from your own files).
- Fast deck/commander search, deck count, and sorting.
- Create, edit, and delete Commander deck profiles.
- Import PNG, JPEG, BMP, WEBP or GIF artwork (copied to local app data).
- Choose mana color identity and 22 trackers, organized into four categories.
- Persistent, offline profiles saved atomically as JSON.
- Automatically imports existing v0.1 Win32 profiles from decks.ini, leaving the original file intact.
- No accounts, telemetry, network dependency, ESP32 connection, or device sync yet.

## Download Windows build (recommended)

On the [Actions page](https://github.com/JohnathanKong/mtg-tracker-desktop/actions), open the most recent successful **Build MTG Tracker Desktop** workflow, then download the **MTGTrackerDesktop-Windows-Portable** artifact.

Extract the **entire** ZIP and run MTGTrackerDesktop.exe. Qt libraries and QML modules are bundled alongside the executable. You do not install Qt, C++, Python, Node.js, or Docker to run it. **Do not move the .exe out of the extracted folder**; it needs the shipped DLLs/plugins.

The Windows build is compiled with MSVC and undergoes an offscreen Qt/QML launch smoke test.

## Building on Windows: important distinction

The app is **C++20 + Qt Quick**, but the included Linux Docker image does not
contain a Windows cross-compiler or Windows Qt libraries. The old v0.1 command
using `cmake/mingw.cmake`, `build/windows`, or the Docker image
`mtg-desktop-builder` is obsolete. Do not reuse it with v0.2.

**To run the Windows app**, download the portable package from a successful
[GitHub Actions run](https://github.com/JohnathanKong/mtg-tracker-desktop/actions)
(the artifact is named `MTGTrackerDesktop-Windows-Portable`), unzip the
*entire folder*, then run `MTGTrackerDesktop.exe`. Windows compilation is
handled by the Windows GitHub Actions runner (MSVC + Qt).

**To verify compilation entirely in Docker** from Windows PowerShell, use
the Linux target:

```powershell
git pull
.\scripts\build-docker.ps1
```

Or use the equivalent manual commands:

```powershell
docker build -t mtg-tracker-desktop-builder .
docker run --rm -v "${PWD}:/src" -w /src mtg-tracker-desktop-builder
```

Both of these create `build/linux/MTGTrackerDesktop`, a **Linux executable
that will not run on Windows**. Do not point this image at the old MinGW toolchain.

## Build inside Docker

The Docker image contains the full C++/Qt development environment, but builds a **Linux** executable (not a Windows .exe). This avoids pretending the Linux Qt SDK can link a Windows Qt app.

With Docker installed, from the project root, run:

    ./scripts/build.sh

Output: build/linux/MTGTrackerDesktop.

A Windows portable package is built with native Windows Qt tooling on GitHub Actions; Docker is not required to run it. If full Linux-to-Windows Qt cross-compilation becomes important, we can add a dedicated MXE-style toolchain in a later release.

## Native developer build

Install Qt 6.4+ with Qt Quick and Qt Quick Controls 2, CMake 3.21+, and a C++20 compiler.

    cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
    cmake --build build --config Release

Only the packaged Windows artifact includes Qt dependencies.

## Data compatibility

This version saves its deck library under:

    %LOCALAPPDATA%\MTGTrackerDesktop\decks.json
    %LOCALAPPDATA%\MTGTrackerDesktop\images\

If an old decks.ini from v0.1 exists and decks.json does not, it imports the old decks once. The original .ini remains as a backup.

The app copies user artwork locally on import. Deleting a profile does not automatically delete its artwork file.

## Counter architecture

Deck profiles, not commander card names, decide which counters are enabled. Universal player trackers are initially selected, but can be customized. You can maintain different profiles for the same commander.

The two projects are separate: this is the deck editor. ESP32 firmware lives at [mtg-tracker](https://github.com/JohnathanKong/mtg-tracker).

## Scope

No Scryfall integration, no card catalog download, no live game counters, and **no ESP32 integration** yet. The library becomes illustrated after you import deck artwork. Empty cards use original abstract procedural artwork rather than copyrighted card art.
