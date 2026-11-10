FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y --no-install-recommends cmake ninja-build g++-mingw-w64-x86-64-posix ca-certificates && rm -rf /var/lib/apt/lists/*
WORKDIR /src
CMD ["sh", "-c", "cmake -S . -B build/windows -G Ninja -DCMAKE_TOOLCHAIN_FILE=cmake/mingw.cmake -DCMAKE_BUILD_TYPE=Release && cmake --build build/windows"]
