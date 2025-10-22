#!/bin/bash
# Typography Automation Script - Phase v1.5 Layers 3 & 4
# Replaces hardcoded fonts with DSTypography tokens
# Industry Pattern: Google Codemods, Facebook Jscodeshift

set -e

echo "🔧 Typography Replacer - Phase v1.5 Layers 3 & 4"
echo "================================================"
echo ""

# Target files
FILE1="FastingTracker/UI/Components/WeightComponents.swift"
FILE2="FastingTracker/WeightControlCenterView.swift"

# Backup files
echo "📦 Creating backups..."
cp "$FILE1" "$FILE1.backup"
cp "$FILE2" "$FILE2.backup"
echo "   ✅ Backups created"
echo ""

echo "🔄 Applying typography token replacements..."
echo ""

# Function to replace in both files
replace_in_both() {
    local SEARCH="$1"
    local REPLACE="$2"
    local DESC="$3"

    echo "   • $DESC"
    sed -i '' "s/$SEARCH/$REPLACE/g" "$FILE1"
    sed -i '' "s/$SEARCH/$REPLACE/g" "$FILE2"
}

# DISPLAY TYPOGRAPHY
replace_in_both \
    '\.font(\.system(size: 34, weight: \.bold))' \
    '.font(DSTypography.screenTitle)' \
    "34pt bold → screenTitle"

replace_in_both \
    '\.font(\.system(size: 60, weight: \.heavy, design: \.rounded))' \
    '.font(DSTypography.displayXXL)' \
    "60pt heavy rounded → displayXXL"

replace_in_both \
    '\.font(\.system(size: 40, weight: \.semibold))' \
    '.font(DSTypography.displayHero)' \
    "40pt semibold → displayHero"

replace_in_both \
    '\.font(\.system(size: 40))' \
    '.font(DSTypography.displayHero)' \
    "40pt → displayHero"

replace_in_both \
    '\.font(\.system(size: 24, weight: \.bold))' \
    '.font(DSTypography.displayM)' \
    "24pt bold → displayM"

replace_in_both \
    '\.font(\.system(size: 20, weight: \.semibold))' \
    '.font(DSTypography.displayS)' \
    "20pt semibold → displayS"

replace_in_both \
    '\.font(\.system(size: 20, weight: \.bold))' \
    '.font(DSTypography.displaySRounded)' \
    "20pt bold → displaySRounded"

# CARD & LIST TYPOGRAPHY
replace_in_both \
    '\.font(\.system(size: 18, weight: \.semibold))' \
    '.font(DSTypography.statValueSmall)' \
    "18pt semibold → statValueSmall"

replace_in_both \
    '\.font(\.system(size: 18, weight: \.medium))' \
    '.font(DSTypography.subtitleLarge)' \
    "18pt medium → subtitleLarge"

replace_in_both \
    '\.font(\.system(size: 17, weight: \.regular))' \
    '.font(DSTypography.subtitleEmphasized)' \
    "17pt regular → subtitleEmphasized"

replace_in_both \
    '\.font(\.system(size: 16, weight: \.semibold))' \
    '.font(DSTypography.cardTitle)' \
    "16pt semibold → cardTitle"

replace_in_both \
    '\.font(\.system(size: 16, weight: \.medium))' \
    '.font(DSTypography.listTitle)' \
    "16pt medium → listTitle"

replace_in_both \
    '\.font(\.system(size: 16, weight: \.regular))' \
    '.font(DSTypography.listTitle)' \
    "16pt regular → listTitle"

replace_in_both \
    '\.font(\.system(size: 16))' \
    '.font(DSTypography.listTitle)' \
    "16pt → listTitle"

replace_in_both \
    '\.font(\.system(size: 14, weight: \.semibold))' \
    '.font(DSTypography.iconButton)' \
    "14pt semibold → iconButton"

replace_in_both \
    '\.font(\.system(size: 14, weight: \.regular))' \
    '.font(DSTypography.cardSubtitle)' \
    "14pt regular → cardSubtitle"

replace_in_both \
    '\.font(\.system(size: 14, weight: \.medium, design: \.rounded))' \
    '.font(DSTypography.iconButton)' \
    "14pt medium rounded → iconButton"

replace_in_both \
    '\.font(\.system(size: 14, weight: \.medium))' \
    '.font(DSTypography.iconButton)' \
    "14pt medium → iconButton"

replace_in_both \
    '\.font(\.system(size: 14, weight: \.bold))' \
    '.font(DSTypography.iconButton)' \
    "14pt bold → iconButton"

replace_in_both \
    '\.font(\.system(size: 14))' \
    '.font(DSTypography.cardSubtitle)' \
    "14pt → cardSubtitle"

replace_in_both \
    '\.font(\.system(size: 13, weight: \.medium))' \
    '.font(DSTypography.labelSecondary)' \
    "13pt medium → labelSecondary"

replace_in_both \
    '\.font(\.system(size: 13))' \
    '.font(DSTypography.cardCaption)' \
    "13pt → cardCaption"

# SMALL TYPOGRAPHY (pills, labels, badges)
replace_in_both \
    '\.font(\.system(size: 12, weight: \.semibold, design: \.rounded))' \
    '.font(DSTypography.periodLabel)' \
    "12pt semibold rounded → periodLabel"

replace_in_both \
    '\.font(\.system(size: 12, weight: \.bold, design: \.rounded))' \
    '.font(DSTypography.pillLabel)' \
    "12pt bold rounded → pillLabel"

replace_in_both \
    '\.font(\.system(size: 12, weight: \.semibold))' \
    '.font(DSTypography.statLabel)' \
    "12pt semibold → statLabel"

replace_in_both \
    '\.font(\.system(size: 12, weight: \.medium))' \
    '.font(DSTypography.statLabel)' \
    "12pt medium → statLabel"

replace_in_both \
    '\.font(\.system(size: 12, weight: \.regular))' \
    '.font(DSTypography.listCaption)' \
    "12pt regular → listCaption"

replace_in_both \
    '\.font(\.system(size: 12))' \
    '.font(DSTypography.listCaption)' \
    "12pt → listCaption"

replace_in_both \
    '\.font(\.system(size: 11, weight: \.bold, design: \.rounded))' \
    '.font(DSTypography.pillLabel)' \
    "11pt bold rounded → pillLabel"

replace_in_both \
    '\.font(\.system(size: 11))' \
    '.font(DSTypography.pillLabel)' \
    "11pt → pillLabel"

echo ""
echo "✅ All replacements complete!"
echo ""

# Show summary
echo "📊 Summary:"
REPLACED_FILE1=$(diff "$FILE1.backup" "$FILE1" | grep "^<" | wc -l)
REPLACED_FILE2=$(diff "$FILE2.backup" "$FILE2" | grep "^<" | wc -l)
echo "   • WeightComponents.swift: $REPLACED_FILE1 lines changed"
echo "   • WeightControlCenterView.swift: $REPLACED_FILE2 lines changed"
echo ""

echo "💾 Backups saved:"
echo "   • $FILE1.backup"
echo "   • $FILE2.backup"
echo ""
echo "🎉 Typography automation complete!"
echo ""
echo "Next steps:"
echo "   1. Review changes: git diff"
echo "   2. Build verification: xcodebuild"
echo "   3. Commit: git commit -m 'feat: Phase v1.5 Layers 3+4'"
echo ""
