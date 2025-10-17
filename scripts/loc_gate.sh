#!/bin/bash
# LOC Gate Script - Enforces Lines of Code limits
# Warns at 300 LOC, fails at 400 LOC

set -e

# Configuration
WARN_THRESHOLD=300
ERROR_THRESHOLD=400
EXIT_CODE=0

# Colors for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo "🔍 Running LOC Gate Check..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Thresholds: ⚠️  >$WARN_THRESHOLD LOC | ❌ >$ERROR_THRESHOLD LOC"
echo ""

# Find all Swift files, excluding certain directories
FILES=$(find FastingTracker -name "*.swift" \
  -not -path "*/Pods/*" \
  -not -path "*/fastlane/*" \
  -not -path "*/.build/*" \
  -not -path "*/DerivedData/*" \
  -not -path "*/.swiftpm/*" \
  -not -path "*/FastingTrackerTests/Fixtures/*" \
  2>/dev/null || true)

if [ -z "$FILES" ]; then
  echo "❌ No Swift files found!"
  exit 1
fi

WARNINGS=()
ERRORS=()
TOTAL_FILES=0
CLEAN_FILES=0

# Check each file
while IFS= read -r file; do
  if [ -z "$file" ]; then
    continue
  fi

  TOTAL_FILES=$((TOTAL_FILES + 1))

  # Count lines (excluding blank lines and comments)
  LOC=$(grep -cvE '^\s*$|^\s*//' "$file" 2>/dev/null || echo "0")

  # Check thresholds
  if [ "$LOC" -gt "$ERROR_THRESHOLD" ]; then
    ERRORS+=("$file: $LOC LOC")
    EXIT_CODE=1
  elif [ "$LOC" -gt "$WARN_THRESHOLD" ]; then
    WARNINGS+=("$file: $LOC LOC")
  else
    CLEAN_FILES=$((CLEAN_FILES + 1))
  fi
done <<< "$FILES"

# Report results
echo "📊 Results:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Total files checked: $TOTAL_FILES"
echo "Clean files (≤$WARN_THRESHOLD LOC): $CLEAN_FILES"
echo ""

# Show errors
if [ ${#ERRORS[@]} -gt 0 ]; then
  echo -e "${RED}❌ ERRORS (>$ERROR_THRESHOLD LOC):${NC}"
  for error in "${ERRORS[@]}"; do
    echo -e "${RED}  $error${NC}"
  done
  echo ""
fi

# Show warnings
if [ ${#WARNINGS[@]} -gt 0 ]; then
  echo -e "${YELLOW}⚠️  WARNINGS (>$WARN_THRESHOLD LOC):${NC}"
  for warning in "${WARNINGS[@]}"; do
    echo -e "${YELLOW}  $warning${NC}"
  done
  echo ""
fi

# Final verdict
if [ ${#ERRORS[@]} -eq 0 ] && [ ${#WARNINGS[@]} -eq 0 ]; then
  echo -e "${GREEN}✅ All files pass LOC limits!${NC}"
elif [ ${#ERRORS[@]} -eq 0 ]; then
  echo -e "${YELLOW}✅ No errors, but ${#WARNINGS[@]} warning(s) found.${NC}"
else
  echo -e "${RED}❌ LOC Gate Failed! ${#ERRORS[@]} file(s) exceed $ERROR_THRESHOLD LOC.${NC}"
  echo -e "${RED}Please refactor files above the error threshold.${NC}"
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

exit $EXIT_CODE
