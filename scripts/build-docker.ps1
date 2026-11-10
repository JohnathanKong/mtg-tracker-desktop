# Run from Windows PowerShell:
#   .\scripts\build-docker.ps1
#
# Builds the Linux C++/Qt application in Docker. The Windows portable application
# is built by GitHub Actions because the Linux Qt SDK cannot link Windows executables.
$ErrorActionPreference = "Stop"
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

Write-Host "Building MTG Tracker Desktop's Linux Qt target in Docker..." -ForegroundColor Cyan
Write-Host "Note: This does NOT produce a Windows .exe." -ForegroundColor Yellow

docker build -t mtg-tracker-desktop-builder $repoRoot
if ($LASTEXITCODE -ne 0) {
    throw "Docker image build failed."
}

docker run --rm --mount "type=bind,source=$repoRoot,target=/src" -w /src mtg-tracker-desktop-builder
if ($LASTEXITCODE -ne 0) {
    throw "C++/Qt compilation failed."
}

Write-Host "Linux binary: build/linux/MTGTrackerDesktop" -ForegroundColor Green
Write-Host "Windows portable EXE: https://github.com/JohnathanKong/mtg-tracker-desktop/actions" -ForegroundColor Cyan
