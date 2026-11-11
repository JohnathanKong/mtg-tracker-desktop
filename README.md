# MTG Tracker Desktop

**MTG Tracker Desktop v0.2** — a cinematic, Windows-first Commander deck library built in native **C++20 + Qt Quick/QML**.

- Grid of illustrated Commander deck cards (artwork from your own files).
- Fast deck/commander search, deck count, and sorting.
- Create, edit, and delete Commander deck profiles.
- Import PNG, JPEG, BMP, WEBP or GIF artwork (copied to local app data).
- Choose mana color identity and built-in trackers organized into categories, with full labels and no truncation.
- Create, rename, enable/disable and delete **named custom trackers** per deck (up to 100).
- Save a **deck list URL** (Moxfield, Archidekt, MTGGoldfish, or any HTTPS/HTTP site) and open it in your browser.
- Use the dedicated **Deck Links** page to access all saved deck lists.
- Persistent, offline profiles saved atomically as JSON.
- Automatically imports existing v0.1 Win32 profiles from decks.ini, leaving the original file intact.
- No accounts, telemetry, network dependency, ESP32 connection, or device sync yet.

## Download Windows build (recommended)

On the [Actions page](https://github.com/JohnathanKong/mtg-tracker-desktop/actions), open the most recent successful **Build MTG Tracker Desktop** workflow, then download the **MTGTrackerDesktop-Windows-Portable** artifact.

Extract the **entire** ZIP and run MTGTrackerDesktop.exe. Qt libraries and QML modules are bundled alongside the executable. You do not install Qt, C++, Python, Node.js, or Docker to run it. **Do not move the .exe out of the extracted folder**; it needs the shipped DLLs/plugins.

The Windows build is compiled with MSVC and undergoes an offscreen Qt/QML launch smoke test.

## Build the WINDOWS application inside Docker (recommended)

The Linux Docker image includes Windows Qt 6, MinGW-w64, CMake, Ninja, and Wine.
It compiles a genuine Windows x64 EXE and packages all required Qt runtime DLLs.
Nothing besides Docker needs to be installed on the Windows host.

From PowerShell in the repository root:

```powershell
git pull
docker build -t mtg-tracker-desktop-builder .
docker run --rm -v "${PWD}:/src" -w /src mtg-tracker-desktop-builder
```

Or use the one-command PowerShell helper:

```powershell
.\scripts\build-docker.ps1
```

Output:

```text
dist/windows/MTGTrackerDesktop.exe
dist/windows/*.dll
dist/windows/platforms/...
dist/windows/qml/...
```

Run dist\windows\MTGTrackerDesktop.exe on Windows. KEEP THE WHOLE dist/windows FOLDER.
No Qt installation is required on the host. This is native C++, not Electron.

The first Docker build downloads a substantial Windows Qt/MinGW image (~1 GB compressed).
Later builds use the Docker cache.

GitHub Actions publishes a Docker-built portable package called
MTGTrackerDesktop-Docker-Windows-x64, in addition to the MSVC Windows package.

Do not reuse the obsolete v0.1 cmake/mingw.cmake build command.
The new container selects the correct Windows compiler automatically.

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

## Custom trackers and deck list links

The deck editor's Custom Trackers panel allows you to type any tracker name
(e.g. "Treasures", "Goblins created" or "Spell copies"), add it, rename it,
toggle whether it is enabled, or remove it entirely. Trackers belong to the
deck profile, not the Commander card. Older profiles using the two default
custom tracker slots migrate to editable names.

The deck editor also has a Deck list URL field. Paste the full `https://`
or `http://` URL for your deck list. The Deck Links sidebar page lists all
decks and lets you open the link in your default web browser; no web requests
or syncing occur inside the app.

## Counter architecture

Deck profiles, not commander card names, decide which counters are enabled. Universal player trackers are initially selected, but can be customized. You can maintain different profiles for the same commander.

The two projects are separate: this is the deck editor. ESP32 firmware lives at [mtg-tracker](https://github.com/JohnathanKong/mtg-tracker).

## Scope

No Scryfall integration, no card catalog download, no live game counters, and **no ESP32 integration** yet. The library becomes illustrated after you import deck artwork. Empty cards use original abstract procedural artwork rather than copyrighted card art.
