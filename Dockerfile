FROM debian:bookworm
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential cmake ninja-build pkg-config \
    qt6-base-dev qt6-declarative-dev qt6-declarative-dev-tools \
    qml6-module-qtquick qml6-module-qtquick-controls \
    qml6-module-qtquick-layouts qml6-module-qtquick-window \
    qml6-module-qtquick-dialogs qml6-module-qtquick-templates \
    qml6-module-qtqml qml6-module-qtqml-models qml6-module-qtqml-workerscript \
    libgl1-mesa-dri libegl1 mesa-utils ca-certificates \
 && rm -rf /var/lib/apt/lists/*
WORKDIR /src
CMD ["sh","-c","cmake -S . -B build/linux -G Ninja -DCMAKE_BUILD_TYPE=Release && cmake --build build/linux --parallel 2"]
