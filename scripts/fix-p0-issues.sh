#!/bin/bash
# P0 Automated Fixes Script
# Following Google/Facebook automation patterns for bulk code fixes
# Industry Standard: Codemod pattern for safe, repeatable transformations

set -e  # Exit on error

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
FASTINGTRACKER_DIR="$PROJECT_ROOT/FastingTracker"

echo "🚀 Starting P0 Automated Fixes"
echo "================================"
echo "Project Root: $PROJECT_ROOT"
echo "Source Directory: $FASTINGTRACKER_DIR"
echo ""

# Function: Replace print() with AppLogger
fix_print_statements() {
    echo "📝 Task 1.2: Replacing print() statements with AppLogger..."

    # Count current print() statements
    PRINT_COUNT=$(grep -r "print(" "$FASTINGTRACKER_DIR" --include="*.swift" | wc -l | tr -d ' ')
    echo "   Found $PRINT_COUNT print() statements"

    if [ "$PRINT_COUNT" -eq 0 ]; then
        echo "   ✅ No print() statements to fix!"
        return
    fi

    # Create backup
    BACKUP_DIR="$PROJECT_ROOT/.backups/p0-fixes-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    echo "   Creating backup at: $BACKUP_DIR"
    cp -R "$FASTINGTRACKER_DIR" "$BACKUP_DIR/"

    # Replace print() with AppLogger.debug()
    # Pattern: print("message") → AppLogger.debug("message", category: .general)
    find "$FASTINGTRACKER_DIR" -name "*.swift" -type f -exec sed -i '' \
        -e 's/print("\(.*\)")/AppLogger.debug("\1", category: .general)/g' \
        {} \;

    # Verify replacements
    NEW_PRINT_COUNT=$(grep -r "print(" "$FASTINGTRACKER_DIR" --include="*.swift" | wc -l | tr -d ' ')
    FIXED_COUNT=$((PRINT_COUNT - NEW_PRINT_COUNT))

    echo "   ✅ Fixed $FIXED_COUNT print() statements"
    echo "   Remaining: $NEW_PRINT_COUNT (should be in comments/doc)"
    echo ""
}

# Function: Fix forced type cast (as!)
fix_forced_type_cast() {
    echo "📝 Task 1.1: Fixing forced type cast (as!)..."

    # Check DataStore.swift forced cast
    DATASTORE_FILE="$FASTINGTRACKER_DIR/Core/Persistence/DataStore.swift"

    if grep -q "as! UserDefaultsDataStore" "$DATASTORE_FILE"; then
        echo "   Found forced cast in DataStore.swift:372"

        # Replace with safe cast
        sed -i '' 's/return shared as! UserDefaultsDataStore/guard let store = shared as? UserDefaultsDataStore else { fatalError("DataStore.shared must be UserDefaultsDataStore") }\
        return store/g' "$DATASTORE_FILE"

        echo "   ✅ Fixed forced type cast with safe guard let"
    else
        echo "   ✅ No forced type casts found"
    fi
    echo ""
}

# Function: Add @MainActor to managers
add_mainactor_annotations() {
    echo "📝 Task 1.3: Adding @MainActor annotations to managers..."

    MANAGERS=(
        "FastingManager"
        "HydrationManager"
        "SleepManager"
        "MoodManager"
    )

    for manager in "${MANAGERS[@]}"; do
        MANAGER_FILE=$(find "$FASTINGTRACKER_DIR" -name "${manager}.swift" -type f)

        if [ -n "$MANAGER_FILE" ]; then
            # Check if @MainActor already exists
            if grep -q "@MainActor" "$MANAGER_FILE"; then
                echo "   ✅ $manager already has @MainActor"
            else
                # Add @MainActor before class declaration
                sed -i '' '/^class '"$manager"': ObservableObject/i\
@MainActor
' "$MANAGER_FILE"
                echo "   ✅ Added @MainActor to $manager"
            fi
        else
            echo "   ⚠️  Could not find ${manager}.swift"
        fi
    done
    echo ""
}

# Function: Verify .swiftlint.yml exists
verify_swiftlint() {
    echo "📝 Task 1.4: Verifying SwiftLint configuration..."

    if [ -f "$PROJECT_ROOT/.swiftlint.yml" ]; then
        echo "   ✅ SwiftLint configuration exists"

        # Check if force_unwrapping rule is enabled
        if grep -q "force_unwrapping" "$PROJECT_ROOT/.swiftlint.yml"; then
            echo "   ✅ force_unwrapping rule is configured"
        else
            echo "   ⚠️  force_unwrapping rule not found - manual config needed"
        fi
    else
        echo "   ⚠️  .swiftlint.yml not found - needs creation"
    fi
    echo ""
}

# Main execution
main() {
    echo "Starting automated P0 fixes..."
    echo ""

    # Task 1.1: Fix forced type casts
    fix_forced_type_cast

    # Task 1.2: Replace print() statements
    fix_print_statements

    # Task 1.3: Add @MainActor annotations
    add_mainactor_annotations

    # Task 1.4: Verify SwiftLint
    verify_swiftlint

    echo "================================"
    echo "✅ Automated P0 fixes complete!"
    echo ""
    echo "Next steps:"
    echo "1. Build project (Cmd+B) to verify changes"
    echo "2. Run tests (Cmd+U) if they exist"
    echo "3. Review backup at: $BACKUP_DIR"
    echo "4. Manual tasks remaining:"
    echo "   - Task 1.5: Create unit tests (manual)"
    echo "   - Task 1.6: Integrate Crashlytics (manual)"
    echo ""
}

# Run main function
main
