# Build Windows x64 Qt Quick from a Linux container with Windows Qt/MinGW.
# Copy the entrypoint into the image instead of executing the host bind-mounted
# script. Windows git checkouts may convert *.sh to CRLF; normalize here.
FROM dalogik/qt-docker:qt6.10.3-win64-mingw
COPY scripts/build-windows.sh /usr/local/bin/mtg-build-windows.sh
RUN sed -i 's/\r$//' /usr/local/bin/mtg-build-windows.sh
WORKDIR /src
CMD ["/bin/bash", "/usr/local/bin/mtg-build-windows.sh"]
