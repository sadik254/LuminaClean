#!/bin/bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR"

echo "Building LuminaClean in Release mode..."
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift build -c release

APP_NAME="LuminaClean.app"
APP_DIR="$DIR/$APP_NAME"
MACOS_DIR="$APP_DIR/Contents/MacOS"
RESOURCES_DIR="$APP_DIR/Contents/Resources"

echo "Creating macOS App Bundle: $APP_NAME"
rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

BIN_PATH="$DIR/.build/release/LuminaClean"
if [ ! -f "$BIN_PATH" ]; then
    BIN_PATH="$DIR/.build/arm64-apple-macosx/release/LuminaClean"
fi

cp "$BIN_PATH" "$MACOS_DIR/LuminaClean"
chmod +x "$MACOS_DIR/LuminaClean"

if [ -f "$DIR/AppIcon.icns" ]; then
    cp "$DIR/AppIcon.icns" "$RESOURCES_DIR/AppIcon.icns"
    echo "Copied AppIcon.icns into app bundle."
fi

cat <<EOF > "$APP_DIR/Contents/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>LuminaClean</string>
    <key>CFBundleIdentifier</key>
    <string>com.luminaclean.app</string>
    <key>CFBundleName</key>
    <string>LuminaClean</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF

echo "App bundle created successfully at: $APP_DIR"
echo "You can launch it with: open \"$APP_DIR\""
