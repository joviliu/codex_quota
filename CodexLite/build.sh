#!/bin/bash
set -e

APP_NAME="CodexLite"
APP_DIR="${APP_NAME}.app"
MACOS_DIR="${APP_DIR}/Contents/MacOS"

# Create directory structure
mkdir -p "$MACOS_DIR"
mkdir -p "${APP_DIR}/Contents/Resources"

# Copy AppIcon if exists
if [ -f "AppIcon.icns" ]; then
    cp AppIcon.icns "${APP_DIR}/Contents/Resources/AppIcon.icns"
fi

# Compile swift file
# We don't strictly need -target arm64-apple-macosx15.0 if we build for the current machine, but it's safe.
swiftc Sources/app.swift -parse-as-library -o "$MACOS_DIR/$APP_NAME"

# Create Info.plist
cat > "${APP_DIR}/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIdentifier</key>
    <string>com.codexlite.mac</string>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>LSUIElement</key>
    <true/>
</dict>
</plist>
EOF

echo "Built ${APP_DIR} successfully"
