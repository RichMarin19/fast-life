#!/bin/bash

set -e

echo "🚀 Building and running Fast lIFe..."

# Run build script
./build.sh

# Get app path from build script
if [ ! -f .app_path ]; then
    echo "❌ App path not found. Build may have failed."
    exit 1
fi

APP_PATH=$(cat .app_path)
BUNDLE_ID="com.fastlife.app"
SIMULATOR="iPhone 16 Pro Max"

echo ""
echo "📱 Launching simulator..."

# Boot simulator if not running
xcrun simctl boot "$SIMULATOR" 2>/dev/null || true

# Wait for simulator to boot
echo "⏳ Waiting for simulator to boot..."
sleep 3

# Open Simulator app
open -a Simulator

# Wait for simulator to be fully ready
sleep 2

echo "📲 Installing app..."
xcrun simctl install booted "$APP_PATH"

echo "🎯 Launching app..."
xcrun simctl launch booted "$BUNDLE_ID"

echo ""
echo "✅ Fast lIFe is now running on $SIMULATOR!"
echo "📍 Bundle ID: $BUNDLE_ID"
