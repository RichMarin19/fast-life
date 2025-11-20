#!/bin/bash

# Deprecate DSColors - Replace with Theme.ColorToken
# Following "simple method first" strategy from HANDOFF.md
# Industry Pattern: Design token consolidation (Apple HIG, Material Design)

echo "═══════════════════════════════════════════════════════════"
echo "🎨 DSColors Deprecation Script"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "Strategy: Replace DSColors.* with Theme.ColorToken.*"
echo "Files affected: DSCard.swift, DSCardHeader.swift"
echo ""

# Target files (only actual source files, not backups)
FILES=(
    "FastingTracker/Core/DesignSystem/DSCard.swift"
    "FastingTracker/Core/DesignSystem/DSCardHeader.swift"
)

# Backup directory
BACKUP_DIR=".backups/dscolors-deprecation-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"

echo "📦 Creating backups in $BACKUP_DIR"
echo ""

# Process each file
for file in "${FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "Processing: $file"

        # Create backup
        cp "$file" "$BACKUP_DIR/$(basename "$file").bak"
        echo "  ✅ Backup created"

        # Count original DSColors references
        original_count=$(grep -o "DSColors\." "$file" | wc -l | tr -d ' ')
        echo "  📊 Found $original_count DSColors references"

        # Apply replacements (escaping dots for sed)
        sed -i '' 's/DSColors\.cardBackground/Theme.ColorToken.card/g' "$file"
        sed -i '' 's/DSColors\.cardShadow/Theme.ColorToken.shadowCard/g' "$file"
        sed -i '' 's/DSColors\.textPrimary/Theme.ColorToken.textPrimary/g' "$file"
        sed -i '' 's/DSColors\.textSecondary/Theme.ColorToken.textSecondary/g' "$file"
        sed -i '' 's/DSColors\.accentPrimary/Theme.ColorToken.accentPrimary/g' "$file"
        sed -i '' 's/DSColors\.accentSuccess/Theme.ColorToken.stateSuccess/g' "$file"
        sed -i '' 's/DSColors\.accentWarning/Theme.ColorToken.stateWarning/g' "$file"
        sed -i '' 's/DSColors\.accentError/Theme.ColorToken.stateError/g' "$file"
        sed -i '' 's/DSColors\.chartLine/Theme.ColorToken.accentPrimary/g' "$file"
        sed -i '' 's/DSColors\.chartGoalLine/Theme.ColorToken.stateSuccess/g' "$file"
        sed -i '' 's/DSColors\.screenBackground/Theme.ColorToken.bgDeepStart/g' "$file"

        # Count remaining DSColors references
        remaining_count=$(grep -o "DSColors\." "$file" | wc -l | tr -d ' ')
        replaced_count=$((original_count - remaining_count))

        echo "  🔄 Replaced $replaced_count references"
        if [ "$remaining_count" -gt 0 ]; then
            echo "  ⚠️  Warning: $remaining_count DSColors references remain (may need manual review)"
        else
            echo "  ✅ All DSColors references replaced"
        fi
        echo ""
    else
        echo "⚠️  File not found: $file"
        echo ""
    fi
done

echo "═══════════════════════════════════════════════════════════"
echo "✅ DSColors deprecation complete!"
echo ""
echo "Next steps:"
echo "1. Run: xcodebuild -scheme FastingTracker build"
echo "2. Verify: grep -r 'DSColors\\.' FastingTracker/Core/DesignSystem"
echo "3. Add deprecation notice to DSColors.swift"
echo "4. Commit changes"
echo "═══════════════════════════════════════════════════════════"
