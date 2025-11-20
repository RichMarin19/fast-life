#!/bin/bash
# Token Warning Hook
# Automatically runs when token threshold is reached

set -e

PROJECT_ROOT="/Users/richmarin/Desktop/FastingTracker"
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
TOKEN_COUNT=${1:-"UNKNOWN"}  # Token count passed as argument
THRESHOLD=${2:-"50000"}      # Threshold passed as argument

echo ""
echo "⚠️ ═══════════════════════════════════════════════════════════════"
echo "⚠️  TOKEN THRESHOLD ALERT"
echo "⚠️ ═══════════════════════════════════════════════════════════════"
echo ""
echo "   Current tokens: $TOKEN_COUNT"
echo "   Threshold: $THRESHOLD"
echo "   Time: $TIMESTAMP"
echo ""

# Log warning
echo "TOKEN WARNING: $TOKEN_COUNT tokens remaining at $TIMESTAMP" >> "$PROJECT_ROOT/.claude/session-history.log"

# Strategic decision guidance
if [ "$TOKEN_COUNT" -lt 30000 ]; then
    echo "🚨 CRITICAL THRESHOLD (<30k tokens)"
    echo ""
    echo "   RECOMMENDED ACTION: STOP AND DOCUMENT"
    echo ""
    echo "   1. Stop current work immediately"
    echo "   2. Create/update status documentation"
    echo "   3. Commit any stable changes"
    echo "   4. Run session-end hook manually"
    echo "   5. Continue in fresh session"
    echo ""
    echo "   ❌ DO NOT:"
    echo "      - Start new layers/phases"
    echo "      - Make large code changes"
    echo "      - Leave code in broken state"
    echo ""
elif [ "$TOKEN_COUNT" -lt 50000 ]; then
    echo "⚠️  WARNING THRESHOLD (<50k tokens)"
    echo ""
    echo "   RECOMMENDED ACTION: FINISH CURRENT LAYER ONLY"
    echo ""
    echo "   1. Complete current layer if nearly done"
    echo "   2. Build and test current changes"
    echo "   3. Commit stable work"
    echo "   4. Update status documentation"
    echo "   5. Plan to stop before next major layer"
    echo ""
    echo "   ⏸️  PAUSE AFTER:"
    echo "      - Current layer completion"
    echo "      - Successful build + test"
    echo "      - Git commit"
    echo ""
fi

# Check current work status
echo "📊 CURRENT STATUS:"
echo ""
if git status --short 2>/dev/null | grep -q .; then
    echo "   Uncommitted changes:"
    git status --short | head -5
else
    echo "   ✅ Working directory clean"
fi
echo ""

echo "📋 NEXT STEPS GUIDANCE:"
echo ""
echo "   Option A: STOP NOW (Recommended if mid-layer)"
echo "      → Update PHASE-*-EXECUTION-STATUS.md"
echo "      → Run: bash .claude/hooks/session-end.sh"
echo "      → Fresh session continues work"
echo ""
echo "   Option B: FINISH LAYER (Only if almost complete)"
echo "      → Complete current layer only"
echo "      → Build + test + commit"
echo "      → Update status docs"
echo "      → Stop before next layer"
echo ""

echo "⚠️ ═══════════════════════════════════════════════════════════════"
echo "⚠️  Review token status and decide: STOP or FINISH LAYER"
echo "⚠️ ═══════════════════════════════════════════════════════════════"
echo ""
