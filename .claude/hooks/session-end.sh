#!/bin/bash
# Session End Hook
# Automatically runs when session is ending (manually triggered or low tokens)

set -e

PROJECT_ROOT="/Users/richmarin/Desktop/FastingTracker"
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
SESSION_LOG="$PROJECT_ROOT/.claude/session-history.log"
STATUS_SNAPSHOT="$PROJECT_ROOT/.claude/session-end-snapshot-$(date +%Y%m%d-%H%M%S).md"

echo "═══════════════════════════════════════════════════════════════"
echo "🏁 SESSION END: $TIMESTAMP"
echo "═══════════════════════════════════════════════════════════════"

# Log session end
echo "SESSION END: $TIMESTAMP" >> "$SESSION_LOG"

# Create session snapshot
cat > "$STATUS_SNAPSHOT" << 'SNAPSHOT_EOF'
# Session End Snapshot
**Date:** $(date +"%B %d, %Y %H:%M:%S")

## Git Status
```
SNAPSHOT_EOF

git status >> "$STATUS_SNAPSHOT" 2>&1 || echo "Git status unavailable" >> "$STATUS_SNAPSHOT"

cat >> "$STATUS_SNAPSHOT" << 'SNAPSHOT_EOF'
```

## Recent Commits (Last 3)
```
SNAPSHOT_EOF

git log --oneline -3 >> "$STATUS_SNAPSHOT" 2>&1 || echo "No commits" >> "$STATUS_SNAPSHOT"

cat >> "$STATUS_SNAPSHOT" << 'SNAPSHOT_EOF'
```

## Modified Files
```
SNAPSHOT_EOF

git diff --name-only >> "$STATUS_SNAPSHOT" 2>&1 || echo "No changes" >> "$STATUS_SNAPSHOT"

cat >> "$STATUS_SNAPSHOT" << 'SNAPSHOT_EOF'
```

## Build Status
SNAPSHOT_EOF

if [ -f "$PROJECT_ROOT/.claude/last-build-status.txt" ]; then
    cat "$PROJECT_ROOT/.claude/last-build-status.txt" >> "$STATUS_SNAPSHOT"
else
    echo "No build status recorded" >> "$STATUS_SNAPSHOT"
fi

cat >> "$STATUS_SNAPSHOT" << 'SNAPSHOT_EOF'

## Next Session Checklist
- [ ] Read POST-COMPRESSION-RESTORATION-PROMPT.md
- [ ] Read PHASE-v1.5-EXECUTION-STATUS.md
- [ ] Check git status for uncommitted work
- [ ] Review this snapshot file
- [ ] Continue from documented phase

---
**Snapshot saved for context restoration**
SNAPSHOT_EOF

echo ""
echo "📸 Session snapshot saved:"
echo "   $STATUS_SNAPSHOT"
echo ""

# Display summary
echo "📊 SESSION SUMMARY:"
echo ""

# Count modified files
MODIFIED_COUNT=$(git diff --name-only 2>/dev/null | wc -l | tr -d ' ')
echo "   Modified files: $MODIFIED_COUNT"

# Check for uncommitted changes
if git status --short 2>/dev/null | grep -q .; then
    echo "   ⚠️  Status: UNCOMMITTED CHANGES"
    echo ""
    echo "   💡 Action Required:"
    echo "      - Review changes in next session"
    echo "      - Complete work or commit if stable"
else
    echo "   ✅ Status: CLEAN (all changes committed)"
fi

echo ""
echo "📋 NEXT SESSION INSTRUCTIONS:"
echo ""
echo "   1. Start with: Read POST-COMPRESSION-RESTORATION-PROMPT.md"
echo "   2. Then read: PHASE-v1.5-EXECUTION-STATUS.md"
echo "   3. Review session snapshot: $(basename "$STATUS_SNAPSHOT")"
echo "   4. Check git status before proceeding"
echo "   5. Continue documented work"
echo ""

echo "═══════════════════════════════════════════════════════════════"
echo "✅ Session ended cleanly. Context preserved!"
echo "═══════════════════════════════════════════════════════════════"
echo ""

# Add to session log
echo "FILES MODIFIED: $MODIFIED_COUNT" >> "$SESSION_LOG"
echo "SNAPSHOT: $STATUS_SNAPSHOT" >> "$SESSION_LOG"
echo "---" >> "$SESSION_LOG"
