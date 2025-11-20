#!/bin/bash
# Replace print() with Log.debug() - Correct Pattern
# Industry Standard: OSLog structured logging (Apple WWDC 2020)

set -e

PROJECT_ROOT="/Users/richmarin/Desktop/FastingTracker"
FASTINGTRACKER_DIR="$PROJECT_ROOT/FastingTracker"

echo "📝 Replacing print() statements with Log.debug()..."
echo "=================================================="

# Create backup
BACKUP_DIR="$PROJECT_ROOT/.backups/print-fixes-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"
echo "Creating backup at: $BACKUP_DIR"
cp -R "$FASTINGTRACKER_DIR" "$BACKUP_DIR/"

# Count before
BEFORE_COUNT=$(grep -r 'print("' "$FASTINGTRACKER_DIR" --include="*.swift" | wc -l | tr -d ' ')
echo "Found $BEFORE_COUNT print() statements"
echo ""

# Replace print() with Log.debug()
# Pattern: print("message") → Log.debug("message", category: .general)
find "$FASTINGTRACKER_DIR" -name "*.swift" -type f -not -path "*/Logging.swift" -exec sed -i '' \
    's/print("\([^"]*\)")/Log.debug("\1", category: .general)/g' \
    {} \;

# Count after
AFTER_COUNT=$(grep -r 'print("' "$FASTINGTRACKER_DIR" --include="*.swift" | wc -l | tr -d ' ')
FIXED_COUNT=$((BEFORE_COUNT - AFTER_COUNT))

echo "✅ Replaced $FIXED_COUNT print() statements"
echo "Remaining: $AFTER_COUNT (should be in Logging.swift or comments)"
echo ""
echo "Backup location: $BACKUP_DIR"
echo ""
echo "Next: Build project to verify (xcodebuild)"
