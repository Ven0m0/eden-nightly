#!/bin/bash

set -e

echo "-- Cloning Eden repository..."
git clone 'https://git.eden-emu.dev/eden-emu/eden.git' ./eden
cd ./eden
echo "   Done."

echo "-- Setup source package information..."
COUNT="$(git rev-list --count HEAD)"
SOURCE_NAME="Eden-${COUNT}-Source-Code"
echo "   Source package name: $SOURCE_NAME"

# Fetch all repo history and cpm pakages
echo "-- Fetching all repo history and cpm pakages..."
git fetch --all
chmod a+x tools/cpm-fetch-all.sh
tools/cpm-fetch-all.sh

# Pack up source for upload
cd ..
mkdir -p artifacts
mkdir "$SOURCE_NAME"
cp -a eden "$SOURCE_NAME"
echo "-- Creating 7z archive: $ZIP_NAME"
ZIP_NAME="$SOURCE_NAME.7z"
7z a -t7z -mx=9 "$ZIP_NAME" "$SOURCE_NAME"
mv -v "$ZIP_NAME" artifacts/

echo "=== ALL DONE! ==="
