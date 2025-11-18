#!/bin/bash
# Find all force unwraps, force casts, and force try statements

set -e

PROJECT_DIR="FastingTracker"

echo "🔍 Scanning for unsafe force operations..."
echo ""

# Colors for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to count occurrences
count_pattern() {
    local pattern=$1
    rg "$pattern" --type swift "$PROJECT_DIR" -c 2>/dev/null | awk -F: '{s+=$2} END {print s+0}'
}

# Find force unwraps
echo "=== FORCE UNWRAPS (!) ==="
UNWRAPS=$(count_pattern '!\s*$|!\s*\)')
if [ "$UNWRAPS" -gt 0 ]; then
    rg '!\s*$|!\s*\)' --type swift "$PROJECT_DIR" -n -A 1 --color always | head -50
    echo ""
else
    echo "✅ None found"
    echo ""
fi

# Find force casts
echo "=== FORCE CASTS (as!) ==="
CASTS=$(count_pattern 'as!')
if [ "$CASTS" -gt 0 ]; then
    rg 'as!' --type swift "$PROJECT_DIR" -n -A 1 --color always | head -20
    echo ""
else
    echo "✅ None found"
    echo ""
fi

# Find force try
echo "=== FORCE TRY (try!) ==="
TRIES=$(count_pattern 'try!')
if [ "$TRIES" -gt 0 ]; then
    rg 'try!' --type swift "$PROJECT_DIR" -n -A 1 --color always | head -20
    echo ""
else
    echo "✅ None found"
    echo ""
fi

# Find implicitly unwrapped optionals in declarations
echo "=== IMPLICITLY UNWRAPPED OPTIONALS (var x: Type!) ==="
IMPLICIT=$(count_pattern ':\s*[A-Z][A-Za-z]*!')
if [ "$IMPLICIT" -gt 0 ]; then
    rg ':\s*[A-Z][A-Za-z]*!' --type swift "$PROJECT_DIR" -n --color always | head -20
    echo ""
else
    echo "✅ None found"
    echo ""
fi

# Summary
echo "📊 Summary:"
echo "  Force unwraps (!): $UNWRAPS"
echo "  Force casts (as!): $CASTS"
echo "  Force try (try!): $TRIES"
echo "  Implicitly unwrapped vars: $IMPLICIT"

TOTAL=$((UNWRAPS + CASTS + TRIES + IMPLICIT))
echo "  TOTAL: $TOTAL unsafe operations"
echo ""

if [ "$TOTAL" -gt 0 ]; then
    echo "💡 How to fix:"
    echo "  - Replace '!' with 'guard let' or 'if let'"
    echo "  - Replace 'as!' with 'as?' and handle nil"
    echo "  - Replace 'try!' with 'try?' or 'do/catch'"
    echo "  - Replace 'var x: Type!' with 'var x: Type?'"
    echo ""
    echo "📖 Target for 8.5/10: <5 total unsafe operations"

    if [ "$TOTAL" -gt 50 ]; then
        echo "❌ Current: $TOTAL (needs significant cleanup)"
    elif [ "$TOTAL" -gt 10 ]; then
        echo "⚠️  Current: $TOTAL (needs cleanup)"
    elif [ "$TOTAL" -gt 5 ]; then
        echo "⚠️  Current: $TOTAL (close to target)"
    else
        echo "✅ Current: $TOTAL (meets target!)"
    fi
else
    echo "🎉 No unsafe operations found! Code is crash-safe."
fi
