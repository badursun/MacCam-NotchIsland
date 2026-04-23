#!/bin/bash
set -euo pipefail

APP_NAME="MacCam"
APP_PATH="/Applications/${APP_NAME}.app"

echo ""
echo "  MacCam — Uninstaller"
echo ""

# Kill if running
pkill -f "${APP_NAME}.app" 2>/dev/null || true

if [ -d "$APP_PATH" ]; then
    rm -rf "$APP_PATH"
    echo "✓ ${APP_PATH} silindi."
else
    echo "– ${APP_PATH} bulunamadi, zaten yuklu degil."
fi

# Clean preferences
defaults delete com.badursun.MacCam 2>/dev/null || true
echo "✓ Tercihler temizlendi."

echo ""
echo "  MacCam kaldirildi."
echo ""
