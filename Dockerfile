# Build a Windows x64 Qt Quick application from a Linux container.
# Qt for Windows, MinGW-w64, CMake, Ninja, and Wine are all preinstalled.
# This is intentionally NOT the Linux Qt SDK.
FROM dalogik/qt-docker:qt6.10.3-win64-mingw
WORKDIR /src
CMD ["/bin/bash", "/src/scripts/build-windows.sh"]
