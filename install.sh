#!/bin/bash
set -euo pipefail

APP_NAME="MacCam"
REPO="badursun/MacCam-NotchIsland"
APP_DEST="/Applications/${APP_NAME}.app"

echo ""
echo "  ╭─────────────────────────────────╮"
echo "  │  MacCam — Notch Island Camera   │"
echo "  ╰─────────────────────────────────╯"
echo ""

# Kill old instance
pkill -f "${APP_NAME}.app" 2>/dev/null || true

TMP_DIR=$(mktemp -d)
trap "rm -rf '$TMP_DIR'" EXIT

# ── Try pre-built binary first (no dev tools needed) ──
echo "→ Checking for pre-built release..."
RELEASE_URL=$(curl -fsSL "https://api.github.com/repos/${REPO}/releases/latest" 2>/dev/null \
    | grep "browser_download_url.*MacCam.app.zip" \
    | head -1 \
    | cut -d '"' -f 4 || true)

if [ -n "$RELEASE_URL" ]; then
    echo "→ Downloading pre-built app..."
    curl -fsSL -o "${TMP_DIR}/MacCam.app.zip" "$RELEASE_URL"
    echo "→ Extracting..."
    ditto -x -k "${TMP_DIR}/MacCam.app.zip" "${TMP_DIR}"

    rm -rf "$APP_DEST"
    cp -R "${TMP_DIR}/${APP_NAME}.app" "$APP_DEST"

    echo ""
    echo "✓ MacCam installed: ${APP_DEST}"
    open "$APP_DEST"
    exit 0
fi

# ── Fallback: build from source ──
echo "– No pre-built release found. Building from source..."

if ! command -v swift &>/dev/null; then
    echo ""
    echo "✗ Swift not found. Install Xcode Command Line Tools:"
    echo "    xcode-select --install"
    echo ""
    echo "  Or wait for a pre-built release at:"
    echo "    https://github.com/${REPO}/releases"
    exit 1
fi

echo "→ Cloning..."
git clone --depth 1 --quiet "https://github.com/${REPO}.git" "${TMP_DIR}/src"

echo "→ Building..."
cd "${TMP_DIR}/src"
swift build -c release --quiet

echo "→ Creating app bundle..."
APP_BUNDLE="${TMP_DIR}/${APP_NAME}.app"
mkdir -p "${APP_BUNDLE}/Contents/MacOS" "${APP_BUNDLE}/Contents/Resources"
cp ".build/release/${APP_NAME}" "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}"
cp "Resources/Info.plist" "${APP_BUNDLE}/Contents/Info.plist"
echo -n "APPL????" > "${APP_BUNDLE}/Contents/PkgInfo"

echo "→ Signing..."
codesign --force --sign - "${APP_BUNDLE}" 2>/dev/null

rm -rf "$APP_DEST"
cp -R "$APP_BUNDLE" "$APP_DEST"

echo ""
echo "✓ MacCam installed: ${APP_DEST}"
echo ""

open "$APP_DEST"
