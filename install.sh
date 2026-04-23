#!/bin/bash
set -euo pipefail

APP_NAME="MacCam"
REPO="https://github.com/badursun/MacCam-NotchIsland.git"
TMP_DIR=$(mktemp -d)
APP_DEST="/Applications/${APP_NAME}.app"

echo ""
echo "  ╭─────────────────────────────────╮"
echo "  │  MacCam — Notch Island Camera   │"
echo "  ╰─────────────────────────────────╯"
echo ""

# Check for swift
if ! command -v swift &>/dev/null; then
    echo "✗ Swift bulunamadi. Xcode Command Line Tools yukleyin:"
    echo "  xcode-select --install"
    exit 1
fi

echo "→ Indiriliyor..."
git clone --depth 1 --quiet "$REPO" "$TMP_DIR"

echo "→ Derleniyor..."
cd "$TMP_DIR"
swift build -c release --quiet

echo "→ App bundle olusturuluyor..."
BUILD_DIR=".build/release"
APP_BUNDLE="${TMP_DIR}/build/${APP_NAME}.app"

mkdir -p "${APP_BUNDLE}/Contents/MacOS"
mkdir -p "${APP_BUNDLE}/Contents/Resources"
cp "${BUILD_DIR}/${APP_NAME}" "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}"
cp "Resources/Info.plist" "${APP_BUNDLE}/Contents/Info.plist"
echo -n "APPL????" > "${APP_BUNDLE}/Contents/PkgInfo"

echo "→ Imzalaniyor..."
codesign --force --sign - "${APP_BUNDLE}" 2>/dev/null

# Kill old instance if running
pkill -f "${APP_NAME}.app" 2>/dev/null || true

echo "→ /Applications klasorune kopyalaniyor..."
rm -rf "$APP_DEST"
cp -R "$APP_BUNDLE" "$APP_DEST"

# Cleanup
rm -rf "$TMP_DIR"

echo ""
echo "✓ MacCam yuklendi: ${APP_DEST}"
echo ""
echo "  Calistirmak icin:"
echo "    open /Applications/MacCam.app"
echo ""
echo "  Menu bar'daki kamera ikonuna tiklayin."
echo "  Sag tik → MacCam'i Kapat"
echo ""

# Launch
open "$APP_DEST"
