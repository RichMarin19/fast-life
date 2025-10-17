#!/bin/bash
# LOC Gate Script - Enforces Lines of Code limits
# Warns at 300 LOC, fails at 400 LOC

set -e

# Configuration
WARN_THRESHOLD=300
ERROR_THRESHOLD=400
EXIT_CODE=0
TREND_LOG_FILE="scripts/.loc_trends.csv"

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
FILE_LOC_MAP=()  # Store file:LOC pairs for trend tracking

# Check each file
while IFS= read -r file; do
  if [ -z "$file" ]; then
    continue
  fi

  TOTAL_FILES=$((TOTAL_FILES + 1))

  # Count lines (excluding blank lines and comments)
  LOC=$(grep -cvE '^\s*$|^\s*//' "$file" 2>/dev/null || echo "0")

  # Store for trend tracking
  FILE_LOC_MAP+=("$file:$LOC")

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

# Log trends (CSV format: timestamp,total_files,clean_files,warnings,errors)
if [ -n "$CI" ]; then
  # Running in CI - log trends
  TIMESTAMP=$(date -u +"%Y-%m-%d %H:%M:%S")
  mkdir -p "$(dirname "$TREND_LOG_FILE")"

  # Create header if file doesn't exist
  if [ ! -f "$TREND_LOG_FILE" ]; then
    echo "timestamp,total_files,clean_files,warnings,errors" > "$TREND_LOG_FILE"
  fi

  echo "$TIMESTAMP,$TOTAL_FILES,$CLEAN_FILES,${#WARNINGS[@]},${#ERRORS[@]}" >> "$TREND_LOG_FILE"
fi

# Show top 10 violators (sorted by LOC descending)
if [ ${#ERRORS[@]} -gt 0 ] || [ ${#WARNINGS[@]} -gt 0 ]; then
  echo ""
  echo "📈 Top 10 Largest Files:"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  # Sort all files by LOC and show top 10
  for entry in "${FILE_LOC_MAP[@]}"; do
    file="${entry%:*}"
    loc="${entry##*:}"
    echo "$loc $file"
  done | sort -rn | head -10 | while read -r loc file; do
    # Color code by threshold
    if [ "$loc" -gt "$ERROR_THRESHOLD" ]; then
      echo -e "${RED}  ❌ $file: $loc LOC${NC}"
    elif [ "$loc" -gt "$WARN_THRESHOLD" ]; then
      echo -e "${YELLOW}  ⚠️  $file: $loc LOC${NC}"
    else
      echo -e "${GREEN}  ✅ $file: $loc LOC${NC}"
    fi
  done
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
fi

exit $EXIT_CODE
