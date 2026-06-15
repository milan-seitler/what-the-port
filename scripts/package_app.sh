#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="$ROOT/outputs/What The Port?.app"
CONTENTS="$APP_DIR/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"
ICONSET="$ROOT/.build/app-icon.iconset"

cd "$ROOT"
swift build -c release

rm -rf "$APP_DIR"
mkdir -p "$MACOS" "$RESOURCES"
cp ".build/release/WhatThePort" "$MACOS/WhatThePort"
if [ -d ".build/release/WhatThePort_WhatThePort.bundle" ]; then
    cp -R ".build/release/WhatThePort_WhatThePort.bundle" "$RESOURCES/"
fi
if [ -f "$ROOT/assets/Logo.png" ]; then
    rm -rf "$ICONSET"
    mkdir -p "$ICONSET"
    sips -z 16 16 "$ROOT/assets/Logo.png" --out "$ICONSET/icon_16x16.png" >/dev/null
    sips -z 32 32 "$ROOT/assets/Logo.png" --out "$ICONSET/icon_16x16@2x.png" >/dev/null
    sips -z 32 32 "$ROOT/assets/Logo.png" --out "$ICONSET/icon_32x32.png" >/dev/null
    sips -z 64 64 "$ROOT/assets/Logo.png" --out "$ICONSET/icon_32x32@2x.png" >/dev/null
    sips -z 128 128 "$ROOT/assets/Logo.png" --out "$ICONSET/icon_128x128.png" >/dev/null
    sips -z 256 256 "$ROOT/assets/Logo.png" --out "$ICONSET/icon_128x128@2x.png" >/dev/null
    sips -z 256 256 "$ROOT/assets/Logo.png" --out "$ICONSET/icon_256x256.png" >/dev/null
    sips -z 512 512 "$ROOT/assets/Logo.png" --out "$ICONSET/icon_256x256@2x.png" >/dev/null
    sips -z 512 512 "$ROOT/assets/Logo.png" --out "$ICONSET/icon_512x512.png" >/dev/null
    cp "$ROOT/assets/Logo.png" "$ICONSET/icon_512x512@2x.png"
    iconutil -c icns "$ICONSET" -o "$RESOURCES/AppIcon.icns"
fi

cat > "$CONTENTS/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>WhatThePort</string>
    <key>CFBundleIdentifier</key>
    <string>io.github.milanseitler.whattheport</string>
    <key>CFBundleName</key>
    <string>What The Port?</string>
    <key>CFBundleDisplayName</key>
    <string>What The Port?</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon.icns</string>
    <key>CFBundleIconName</key>
    <string>AppIcon</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>100</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
</dict>
</plist>
PLIST

echo "$APP_DIR"
