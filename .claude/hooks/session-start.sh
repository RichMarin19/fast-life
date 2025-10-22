#!/bin/bash
# Session Start Hook
# Automatically runs at the beginning of each Claude Code session

set -e

PROJECT_ROOT="/Users/richmarin/Desktop/FastingTracker"
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
SESSION_LOG="$PROJECT_ROOT/.claude/session-history.log"

echo "═══════════════════════════════════════════════════════════════"
echo "🚀 SESSION START: $TIMESTAMP"
echo "═══════════════════════════════════════════════════════════════"

# Log session start
echo "" >> "$SESSION_LOG"
echo "SESSION START: $TIMESTAMP" >> "$SESSION_LOG"

# Display critical context files
echo ""
echo "📋 REQUIRED READING (Context Restoration):"
echo ""
echo "1. POST-COMPRESSION-RESTORATION-PROMPT.md - START HERE FIRST"
echo "2. PHASE-v1.5-EXECUTION-STATUS.md - Current phase status"
echo "3. WEIGHT-TRACKER-PERFECTION-GAMEPLAN.md - Overall gameplan"
echo "4. ReadMeFirst.md - Master gameplan"
echo ""

# Check for pending work
if [ -f "$PROJECT_ROOT/PHASE-v1.5-EXECUTION-STATUS.md" ]; then
    PHASE_STATUS=$(grep "^\*\*Status:\*\*" "$PROJECT_ROOT/PHASE-v1.5-EXECUTION-STATUS.md" | head -1)
    echo "📊 Current Phase Status:"
    echo "   $PHASE_STATUS"
    echo ""
fi

# Check git status
echo "🔍 Git Status Check:"
if git status --short 2>/dev/null | grep -q .; then
    echo "   ⚠️  Uncommitted changes detected:"
    git status --short | head -5
    echo ""
    echo "   💡 Review changes before proceeding"
else
    echo "   ✅ Working directory clean"
fi
echo ""

# Check build status
echo "🏗️  Last Build Status:"
if [ -f "$PROJECT_ROOT/.claude/last-build-status.txt" ]; then
    cat "$PROJECT_ROOT/.claude/last-build-status.txt"
else
    echo "   ℹ️  No previous build record"
fi
echo ""

# Display strategy reminder
echo "📐 DEVELOPMENT STRATEGY (Always Follow):"
echo "   1. Simple method first, one layer at a time"
echo "   2. Always follow industry leaders and official tech stack"
echo "   3. Do NOT assume, confirm"
echo "   4. Review handoff docs for pitfalls"
echo "   5. Never change working code"
echo ""

# Token budget display
echo "💰 Token Budget: FULL (200,000 tokens available)"
echo ""

echo "═══════════════════════════════════════════════════════════════"
echo "✅ Session initialized. Ready to work!"
echo "═══════════════════════════════════════════════════════════════"
echo ""
