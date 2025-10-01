#!/bin/bash

set -e

echo "🔨 Building Fast lIFe..."

# Project configuration
PROJECT="FastingTracker.xcodeproj"
SCHEME="FastingTracker"
CONFIGURATION="Debug"
DESTINATION="platform=iOS Simulator,name=iPhone 16 Pro Max"

# Clean and build
xcodebuild -project "$PROJECT" \
    -scheme "$SCHEME" \
    -configuration "$CONFIGURATION" \
    -destination "$DESTINATION" \
    clean build \
    -quiet

# Find the built app
BUILD_DIR=$(xcodebuild -project "$PROJECT" -scheme "$SCHEME" -configuration "$CONFIGURATION" -showBuildSettings | grep -m 1 "BUILD_DIR" | sed 's/.*= //')
APP_PATH="$BUILD_DIR/$CONFIGURATION-iphonesimulator/Fast lIFe.app"

if [ -d "$APP_PATH" ]; then
    echo "✅ Build successful!"
    echo "📦 App location: $APP_PATH"
    echo "$APP_PATH" > .app_path
else
    echo "❌ Build failed - app not found"
    exit 1
fi
