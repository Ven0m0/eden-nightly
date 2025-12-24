#!/usr/bin/env bash
# shellcheck enable=all shell=bash source-path=SCRIPTDIR
shopt -s nullglob globstar
IFS=$'\n\t' LC_ALL=C

command -v cmake &>/dev/null || exit 1
command -v llvm-profdata &>/dev/null || exit 1

cd eden
cmake --fresh -G Ninja -S . -B build \
-DYUZU_USE_BUNDLED_QT=OFF \
-DYUZU_USE_BUNDLED_FFMPEG=ON \
-DYUZU_USE_BUNDLED_SIRIT=ON \
-DYUZU_SYSTEM_PROFILE=steamdeck \
-DYUZU_USE_EXTERNAL_SDL2=ON \
-DYUZU_USE_CPM=ON \
-DYUZU_USE_FASTER_LD=ON \
-DBUILD_TESTING=OFF -DYUZU_TESTS=OFF -DDYNARMIC_TESTS=OFF \
-DYUZU_CMD=OFF \
-DYUZU_ROOM=ON \
-DYUZU_ROOM_STANDALONE=OFF \
-DUSE_DISCORD_PRESENCE=ON \
-DENABLE_QT_TRANSLATION=OFF \
-DENABLE_UPDATE_CHECKER=OFF \
-DCMAKE_BUILD_TYPE=Release \
-DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++ \
-DCMAKE_CXX_FLAGS="-march=znver2 -mtune=znver2 -pipe -fuse-ld=lld -fprofile-generate -w" \
-DCMAKE_C_FLAGS="-march=znver2 -mtune=znver2 -pipe -fuse-ld=lld -fprofile-generate -w" \
-DCMAKE_EXE_LINKER_FLAGS="-Wl,--as-needed" \
-DCMAKE_SYSTEM_PROCESSOR=x86_64
cmake --build build -j "$(nproc)"

# workload run, each run with only one game
cd build
LLVM_PROFILE_FILE="eden-%p.profraw" ./bin/eden

# merge multiple profraw files into one profdata file
llvm-profdata merge --output="eden.profdata" eden-*.profraw

# or just zip profraw files for uploading
version="$(git rev-list --count HEAD)"
7z a -t7z ../$"version".7z eden-*.profraw

# cleanup
cd ..
sudo rm -rf ./build

