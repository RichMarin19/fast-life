#!/bin/bash
# Migrate print() statements to AppLogger

set -e

PROJECT_DIR="FastingTracker"

echo "🔍 Finding all print() statements..."
echo ""

# Count total print statements
TOTAL=$(rg "print\(" --type swift "$PROJECT_DIR" -c 2>/dev/null | awk -F: '{s+=$2} END {print s}')

if [ -z "$TOTAL" ] || [ "$TOTAL" -eq 0 ]; then
    echo "✅ No print() statements found! Already migrated."
    exit 0
fi

echo "Found $TOTAL print() statements to migrate"
echo ""

# Process each file
rg "print\(" --type swift "$PROJECT_DIR" -l 2>/dev/null | while read -r file; do
    echo "📝 Processing: $file"

    # Backup original
    cp "$file" "$file.backup"

    # Replace patterns
    # Error patterns
    sed -i '' 's/print("Error: \(.*\)")/AppLogger.app.error("\1")/g' "$file"
    sed -i '' 's/print("Failed to \(.*\)")/AppLogger.app.error("Failed to \1")/g' "$file"
    sed -i '' 's/print("Error \(.*\)")/AppLogger.app.error("\1")/g' "$file"

    # HealthKit patterns
    sed -i '' 's/print("HealthKit \(.*\)")/AppLogger.healthKit.info("\1")/g' "$file"
    sed -i '' 's/print("Fetching \(.*\) from HealthKit")/AppLogger.healthKit.debug("Fetching \1 from HealthKit")/g' "$file"
    sed -i '' 's/print("Syncing \(.*\) to HealthKit")/AppLogger.healthKit.debug("Syncing \1 to HealthKit")/g' "$file"

    # Notification patterns
    sed -i '' 's/print("Notification \(.*\)")/AppLogger.notifications.info("\1")/g' "$file"
    sed -i '' 's/print("Scheduling \(.*\)")/AppLogger.notifications.debug("Scheduling \1")/g' "$file"

    # Warning patterns
    sed -i '' 's/print("Warning: \(.*\)")/AppLogger.app.warning("\1")/g' "$file"

    # Generic patterns (use debug for everything else)
    sed -i '' 's/print("\(.*\)")/AppLogger.app.debug("\1")/g' "$file"

    echo "  ✅ Updated: $file (backup: $file.backup)"
done

echo ""
echo "🎉 Migration complete!"
echo ""
echo "📋 Next steps:"
echo "1. Review changes: git diff"
echo "2. Test the app to ensure logging works"
echo "3. If satisfied, delete backups: find . -name '*.backup' -delete"
echo "4. Commit: git add . && git commit -m 'refactor: migrate print() to AppLogger'"
echo ""
echo "💡 Check Console.app to see structured logs"
