#!/bin/bash
# Automated TestFlight deployment script

set -e

# Configuration
SCHEME="FastingTracker"
PROJECT="FastingTracker.xcodeproj"
ARCHIVE_PATH="build/FastingTracker.xcarchive"
EXPORT_PATH="build/export"
EXPORT_OPTIONS="ExportOptions.plist"

echo "🚀 Starting TestFlight deployment..."
echo ""

# Check environment variables
if [ -z "$APPLE_ID" ]; then
    echo "⚠️  Warning: APPLE_ID not set"
    echo "   Set with: export APPLE_ID=\"your@email.com\""
    echo ""
fi

if [ -z "$APP_SPECIFIC_PASSWORD" ]; then
    echo "⚠️  Warning: APP_SPECIFIC_PASSWORD not set"
    echo "   Generate at: https://appleid.apple.com/account/manage"
    echo "   Set with: export APP_SPECIFIC_PASSWORD=\"xxxx-xxxx-xxxx-xxxx\""
    echo ""
fi

# Check for ExportOptions.plist
if [ ! -f "$EXPORT_OPTIONS" ]; then
    echo "⚠️  ExportOptions.plist not found. Creating..."
    cat > "$EXPORT_OPTIONS" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>uploadSymbols</key>
    <true/>
    <key>uploadBitcode</key>
    <false/>
</dict>
</plist>
EOF
    echo "✅ Created ExportOptions.plist"
    echo ""
fi

# 1. Clean build
echo "🧹 Cleaning previous builds..."
xcodebuild clean -project "$PROJECT" -scheme "$SCHEME"
rm -rf "$ARCHIVE_PATH" "$EXPORT_PATH"
echo ""

# 2. Run tests
echo "🧪 Running tests..."
xcodebuild test \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
    -quiet
echo "✅ Tests passed"
echo ""

# 3. Archive
echo "📦 Creating archive (this may take a few minutes)..."
xcodebuild archive \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -archivePath "$ARCHIVE_PATH"
echo "✅ Archive created"
echo ""

# 4. Export IPA
echo "📤 Exporting IPA..."
xcodebuild -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportPath "$EXPORT_PATH" \
    -exportOptionsPlist "$EXPORT_OPTIONS"
echo "✅ IPA exported"
echo ""

# 5. Upload to TestFlight
if [ -n "$APPLE_ID" ] && [ -n "$APP_SPECIFIC_PASSWORD" ]; then
    echo "☁️  Uploading to TestFlight..."
    xcrun altool --upload-app \
        --type ios \
        --file "$EXPORT_PATH/$SCHEME.ipa" \
        --username "$APPLE_ID" \
        --password "$APP_SPECIFIC_PASSWORD"

    echo "✅ Uploaded to TestFlight!"
    echo ""
    echo "🔗 Check status: https://appstoreconnect.apple.com"
    echo "⏱  Processing takes ~10-15 minutes"
else
    echo "⚠️  Skipping upload (credentials not set)"
    echo "   IPA available at: $EXPORT_PATH/$SCHEME.ipa"
    echo ""
    echo "To upload manually:"
    echo "1. Open Xcode"
    echo "2. Window > Organizer"
    echo "3. Select archive and click 'Distribute App'"
fi

echo ""
echo "🎉 Deployment complete!"
