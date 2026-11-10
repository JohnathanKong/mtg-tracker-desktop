# From the repository root, on Windows with Docker Desktop:
#   .\scripts\build-docker.ps1
# No Qt/MinGW/CMake installation is needed on Windows.
$ErrorActionPreference = "Stop"
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

Write-Host "Building portable Windows MTG Tracker Desktop with Docker..." -ForegroundColor Cyan
docker build -t mtg-tracker-desktop-builder $repoRoot
if ($LASTEXITCODE -ne 0) { throw "Docker image build failed." }

docker run --rm --mount "type=bind,source=$repoRoot,target=/src" -w /src mtg-tracker-desktop-builder
if ($LASTEXITCODE -ne 0) { throw "Windows Qt cross-compilation failed." }

Write-Host "Windows application: dist\windows\MTGTrackerDesktop.exe" -ForegroundColor Green
Write-Host "Copy the ENTIRE dist\windows folder to run on Windows." -ForegroundColor Cyan
