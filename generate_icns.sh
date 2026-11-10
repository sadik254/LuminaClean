#!/bin/bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR"

INPUT_IMG="$1"
if [ -z "$INPUT_IMG" ] || [ ! -f "$INPUT_IMG" ]; then
    echo "Usage: $0 <path-to-image>"
    exit 1
fi

ICONSET="AppIcon.iconset"
rm -rf "$ICONSET"
mkdir -p "$ICONSET"

echo "Creating iconset resolutions from $INPUT_IMG..."
sips -s format png -z 16 16     "$INPUT_IMG" --out "$ICONSET/icon_16x16.png" > /dev/null
sips -s format png -z 32 32     "$INPUT_IMG" --out "$ICONSET/icon_16x16@2x.png" > /dev/null
sips -s format png -z 32 32     "$INPUT_IMG" --out "$ICONSET/icon_32x32.png" > /dev/null
sips -s format png -z 64 64     "$INPUT_IMG" --out "$ICONSET/icon_32x32@2x.png" > /dev/null
sips -s format png -z 128 128   "$INPUT_IMG" --out "$ICONSET/icon_128x128.png" > /dev/null
sips -s format png -z 256 256   "$INPUT_IMG" --out "$ICONSET/icon_128x128@2x.png" > /dev/null
sips -s format png -z 256 256   "$INPUT_IMG" --out "$ICONSET/icon_256x256.png" > /dev/null
sips -s format png -z 512 512   "$INPUT_IMG" --out "$ICONSET/icon_256x256@2x.png" > /dev/null
sips -s format png -z 512 512   "$INPUT_IMG" --out "$ICONSET/icon_512x512.png" > /dev/null
sips -s format png -z 1024 1024 "$INPUT_IMG" --out "$ICONSET/icon_512x512@2x.png" > /dev/null

echo "Compiling to AppIcon.icns..."
iconutil -c icns "$ICONSET" -o AppIcon.icns
rm -rf "$ICONSET"

echo "Done! AppIcon.icns created at: $DIR/AppIcon.icns"
