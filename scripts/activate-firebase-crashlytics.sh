#!/bin/bash
# Activate Firebase Crashlytics in CrashReportManager.swift
# Assumes Firebase SDK already added via SPM (manual step)
# Industry Standard: Google Firebase Crashlytics for iOS production monitoring

set -e

PROJECT_ROOT="/Users/richmarin/Desktop/FastingTracker"
CRASH_MANAGER_FILE="$PROJECT_ROOT/FastingTracker/CrashReportManager.swift"
APP_FILE="$PROJECT_ROOT/FastingTracker/FastingTrackerApp.swift"

echo "🔥 Activating Firebase Crashlytics"
echo "======================================"
echo ""

# Backup files
BACKUP_DIR="$PROJECT_ROOT/.backups/firebase-activation-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"
echo "📦 Creating backup at: $BACKUP_DIR"
cp "$CRASH_MANAGER_FILE" "$BACKUP_DIR/CrashReportManager.swift"
cp "$APP_FILE" "$BACKUP_DIR/FastingTrackerApp.swift"

# Step 1: Add Firebase imports to CrashReportManager.swift
echo ""
echo "Step 1: Adding Firebase imports to CrashReportManager.swift..."

# Check if imports already exist
if grep -q "import Firebase" "$CRASH_MANAGER_FILE"; then
    echo "✅ Firebase imports already present"
else
    # Add imports after existing imports (after line 3 - after UIKit)
    sed -i '' '3a\
import Firebase\
import FirebaseCrashlytics
' "$CRASH_MANAGER_FILE"
    echo "✅ Added Firebase imports"
fi

# Step 2: Uncomment Firebase initialization in initialize() method
echo ""
echo "Step 2: Activating Firebase initialization..."

# Replace the commented Firebase initialization with actual code
sed -i '' 's|// FirebaseApp.configure()|FirebaseApp.configure()|g' "$CRASH_MANAGER_FILE"
sed -i '' 's|// Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(true)|Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(true)|g' "$CRASH_MANAGER_FILE"

echo "✅ Firebase initialization activated"

# Step 3: Uncomment Firebase crash recording in recordError()
echo ""
echo "Step 3: Activating crash recording..."

# Uncomment the three Crashlytics recording lines
sed -i '' 's|// Crashlytics.crashlytics().record(error: error)|Crashlytics.crashlytics().record(error: error)|g' "$CRASH_MANAGER_FILE"
sed -i '' 's|// Crashlytics.crashlytics().setCustomKeys(context)|// Note: setCustomKeys replaced with loop below|g' "$CRASH_MANAGER_FILE"
sed -i '' 's|// Crashlytics.crashlytics().log("Category: \\(category.rawValue)")|Crashlytics.crashlytics().log("Category: \\(category.rawValue)")|g' "$CRASH_MANAGER_FILE"

# Add custom keys individually (setCustomKeys doesn't exist, need setCustomValue)
sed -i '' '/Crashlytics.crashlytics().record(error: error)/a\
        for (key, value) in context {\
            Crashlytics.crashlytics().setCustomValue(value, forKey: key)\
        }
' "$CRASH_MANAGER_FILE"

echo "✅ Crash recording activated"

# Step 4: Uncomment custom logging
echo ""
echo "Step 4: Activating custom logging..."

sed -i '' 's|// Crashlytics.crashlytics().log(logMessage)|Crashlytics.crashlytics().log(logMessage)|g' "$CRASH_MANAGER_FILE"

echo "✅ Custom logging activated"

# Step 5: Uncomment user context setting
echo ""
echo "Step 5: Activating user context..."

sed -i '' 's|// Crashlytics.crashlytics().setUserID(hashedID)|Crashlytics.crashlytics().setUserID(hashedID)|g' "$CRASH_MANAGER_FILE"
sed -i '' 's|// Crashlytics.crashlytics().setCustomValue(value, forKey: key)|Crashlytics.crashlytics().setCustomValue(value, forKey: key)|g' "$CRASH_MANAGER_FILE"

echo "✅ User context activated"

# Step 6: Update .gitignore
echo ""
echo "Step 6: Updating .gitignore..."

GITIGNORE_FILE="$PROJECT_ROOT/.gitignore"

if [ -f "$GITIGNORE_FILE" ]; then
    if ! grep -q "GoogleService-Info.plist" "$GITIGNORE_FILE"; then
        echo "" >> "$GITIGNORE_FILE"
        echo "# Firebase Configuration" >> "$GITIGNORE_FILE"
        echo "GoogleService-Info.plist" >> "$GITIGNORE_FILE"
        echo "google-services.json" >> "$GITIGNORE_FILE"
        echo "✅ Added Firebase files to .gitignore"
    else
        echo "✅ .gitignore already configured"
    fi
else
    echo "⚠️  No .gitignore found - create one manually"
fi

echo ""
echo "======================================"
echo "✅ Firebase Crashlytics Activation Complete!"
echo ""
echo "📋 Next Steps (MANUAL):"
echo ""
echo "1. Add Firebase SDK via SPM (if not already done):"
echo "   - Xcode → File → Add Package Dependencies"
echo "   - URL: https://github.com/firebase/firebase-ios-sdk.git"
echo "   - Select: FirebaseCrashlytics, FirebaseAnalytics"
echo ""
echo "2. Add GoogleService-Info.plist to project:"
echo "   - Download from Firebase Console"
echo "   - Drag into Xcode project root"
echo "   - Check 'Copy items if needed'"
echo "   - Check 'FastingTracker' target"
echo ""
echo "3. Add -ObjC linker flag:"
echo "   - Project → Target → Build Settings"
echo "   - Search: 'Other Linker Flags'"
echo "   - Add: -ObjC"
echo ""
echo "4. Build and test:"
echo "   xcodebuild build -project FastingTracker.xcodeproj -scheme FastingTracker"
echo ""
echo "📦 Backup location: $BACKUP_DIR"
