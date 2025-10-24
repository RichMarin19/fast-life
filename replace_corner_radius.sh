#!/bin/bash

# Corner Radius Token Replacement Script
# Purpose: Replace hardcoded corner radius values with DSCornerRadius tokens
# Strategy: Conservative, explicit replacements following Apple HIG 2025 standards
# Reference: PERFORMANCE-RECOVERY-ROADMAP.md Task 1.4

# Color codes for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}Corner Radius Token Replacement Script${NC}"
echo -e "${BLUE}Phase 1.4: Performance Recovery - Design Token Migration${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Counters
total_files=0
total_replacements=0

# File patterns to process (exclude Legacy, backup files, and HANDOFF.md)
TARGET_DIR="FastingTracker"

# Find all Swift files, excluding certain directories
files=$(find "$TARGET_DIR" -name "*.swift" \
    -not -path "*/Legacy/*" \
    -not -path "*/.build/*" \
    -not -path "*/DerivedData/*" \
    -not -name "*.backup" \
    -not -name "DSCornerRadius.swift")

echo -e "${YELLOW}📂 Scanning Swift files for hardcoded corner radius values...${NC}"
echo ""

# Replacement patterns based on Apple HIG 2025 standards
# Pattern: cornerRadius: 14 → cornerRadius: DSCornerRadius.banner
# Pattern: cornerRadius: 12 → cornerRadius: DSCornerRadius.card
# Pattern: cornerRadius: 8 → cornerRadius: DSCornerRadius.button
# Pattern: .cornerRadius(14) → .cornerRadius(DSCornerRadius.banner)
# Pattern: .cornerRadius(12) → .cornerRadius(DSCornerRadius.card)
# Pattern: .cornerRadius(8) → .cornerRadius(DSCornerRadius.button)

for file in $files; do
    # Skip if file doesn't exist (race condition check)
    [[ ! -f "$file" ]] && continue

    # Check if file contains hardcoded corner radius
    if grep -q '\bcornerRadius\s*:\s*\d\+\|\bcornerRadius(\d\+)' "$file"; then
        echo -e "${GREEN}Processing: $file${NC}"

        file_changes=0

        # Create backup
        cp "$file" "$file.bak"

        # Replace cornerRadius: 14 with cornerRadius: DSCornerRadius.banner
        if grep -q 'cornerRadius\s*:\s*14\b' "$file"; then
            sed -i '' 's/cornerRadius: 14\b/cornerRadius: DSCornerRadius.banner/g' "$file"
            changes=$(grep -c 'DSCornerRadius.banner' "$file")
            if [[ $changes -gt 0 ]]; then
                echo "  ✓ Replaced 'cornerRadius: 14' → DSCornerRadius.banner"
                ((file_changes += changes))
            fi
        fi

        # Replace .cornerRadius(14) with .cornerRadius(DSCornerRadius.banner)
        if grep -q '\.cornerRadius(14)' "$file"; then
            sed -i '' 's/\.cornerRadius(14)/.cornerRadius(DSCornerRadius.banner)/g' "$file"
            changes=$(grep -c '\.cornerRadius(DSCornerRadius.banner)' "$file")
            if [[ $changes -gt 0 ]]; then
                echo "  ✓ Replaced '.cornerRadius(14)' → .cornerRadius(DSCornerRadius.banner)"
                ((file_changes += changes))
            fi
        fi

        # Replace cornerRadius: 12 with cornerRadius: DSCornerRadius.card
        if grep -q 'cornerRadius\s*:\s*12\b' "$file"; then
            sed -i '' 's/cornerRadius: 12\b/cornerRadius: DSCornerRadius.card/g' "$file"
            changes=$(grep -c 'DSCornerRadius.card' "$file")
            if [[ $changes -gt 0 ]]; then
                echo "  ✓ Replaced 'cornerRadius: 12' → DSCornerRadius.card"
                ((file_changes += changes))
            fi
        fi

        # Replace .cornerRadius(12) with .cornerRadius(DSCornerRadius.card)
        if grep -q '\.cornerRadius(12)' "$file"; then
            sed -i '' 's/\.cornerRadius(12)/.cornerRadius(DSCornerRadius.card)/g' "$file"
            changes=$(grep -c '\.cornerRadius(DSCornerRadius.card)' "$file")
            if [[ $changes -gt 0 ]]; then
                echo "  ✓ Replaced '.cornerRadius(12)' → .cornerRadius(DSCornerRadius.card)"
                ((file_changes += changes))
            fi
        fi

        # Replace cornerRadius: 8 with cornerRadius: DSCornerRadius.button
        if grep -q 'cornerRadius\s*:\s*8\b' "$file"; then
            sed -i '' 's/cornerRadius: 8\b/cornerRadius: DSCornerRadius.button/g' "$file"
            changes=$(grep -c 'DSCornerRadius.button' "$file")
            if [[ $changes -gt 0 ]]; then
                echo "  ✓ Replaced 'cornerRadius: 8' → DSCornerRadius.button"
                ((file_changes += changes))
            fi
        fi

        # Replace .cornerRadius(8) with .cornerRadius(DSCornerRadius.button)
        if grep -q '\.cornerRadius(8)' "$file"; then
            sed -i '' 's/\.cornerRadius(8)/.cornerRadius(DSCornerRadius.button)/g' "$file"
            changes=$(grep -c '\.cornerRadius(DSCornerRadius.button)' "$file")
            if [[ $changes -gt 0 ]]; then
                echo "  ✓ Replaced '.cornerRadius(8)' → .cornerRadius(DSCornerRadius.button)"
                ((file_changes += changes))
            fi
        fi

        if [[ $file_changes -gt 0 ]]; then
            ((total_files++))
            ((total_replacements += file_changes))
            echo "  📊 Total changes in file: $file_changes"
        else
            # No changes made, restore backup
            mv "$file.bak" "$file"
        fi

        echo ""
    fi
done

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ Replacement Complete${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "📊 ${YELLOW}Summary:${NC}"
echo -e "  • Files modified: ${GREEN}$total_files${NC}"
echo -e "  • Total replacements: ${GREEN}$total_replacements${NC}"
echo ""
echo -e "${YELLOW}📝 Next Steps:${NC}"
echo -e "  1. Review changes: ${BLUE}git diff${NC}"
echo -e "  2. Build project: ${BLUE}xcodebuild clean build -scheme FastingTracker${NC}"
echo -e "  3. If build succeeds, remove backups: ${BLUE}find FastingTracker -name '*.swift.bak' -delete${NC}"
echo -e "  4. If build fails, restore backups: ${BLUE}find FastingTracker -name '*.swift.bak' -exec bash -c 'mv \"\$0\" \"\${0%.bak}\"' {} \\;${NC}"
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
