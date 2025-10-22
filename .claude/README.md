# Claude Code Automated Session Management System

**Created:** October 22, 2025
**Purpose:** Automate session boundaries, token optimization, and context preservation
**Status:** Active and configured

---

## 🎯 WHAT THIS SYSTEM DOES

This automated system ensures every Claude Code session:
1. **Starts with full context** (reads restoration prompts automatically)
2. **Monitors token usage** (warns at 50k and 30k thresholds)
3. **Ends cleanly** (creates snapshots, logs status, preserves context)
4. **Prevents broken states** (never leaves code partially complete)
5. **Tracks history** (maintains session logs and snapshots)

**Industry Leader Pattern:** Apple's Xcode build phases, Google's Bazel lifecycle hooks

---

## 📁 FILE STRUCTURE

```
.claude/
├── settings.json                 # Configuration (hooks, thresholds)
├── README.md                     # This file (system documentation)
├── end-session.sh                # Manual session end trigger
├── session-history.log           # Running log of all sessions
├── last-build-status.txt         # Last build result
├── session-end-snapshot-*.md     # Snapshots from each session end
└── hooks/
    ├── session-start.sh          # Auto-runs at session start
    ├── session-end.sh            # Auto-runs at session end
    └── token-warning.sh          # Auto-runs at token thresholds
```

---

## 🚀 HOW IT WORKS

### Session Start (Automatic)
**Trigger:** When you start a new Claude Code session

**What Happens:**
1. Displays required reading list (restoration prompts)
2. Shows current phase status
3. Checks git status for uncommitted work
4. Displays last build status
5. Reminds you of development strategy
6. Shows full token budget (200k)

**Output Example:**
```
═══════════════════════════════════════════════════════════════
🚀 SESSION START: October 22, 2025 14:30:00
═══════════════════════════════════════════════════════════════

📋 REQUIRED READING (Context Restoration):

1. POST-COMPRESSION-RESTORATION-PROMPT.md - START HERE FIRST
2. PHASE-v1.5-EXECUTION-STATUS.md - Current phase status
3. WEIGHT-TRACKER-PERFECTION-GAMEPLAN.md - Overall gameplan
4. ReadMeFirst.md - Master gameplan

📊 Current Phase Status:
   **Status:** 📋 READY FOR EXECUTION

🔍 Git Status Check:
   ✅ Working directory clean

💰 Token Budget: FULL (200,000 tokens available)

✅ Session initialized. Ready to work!
```

---

### Token Warning (Automatic)
**Triggers:**
- **50k tokens remaining:** Warning threshold
- **30k tokens remaining:** Critical threshold

**What Happens:**

#### Warning Threshold (<50k)
```
⚠️  WARNING THRESHOLD (<50k tokens)

RECOMMENDED ACTION: FINISH CURRENT LAYER ONLY

1. Complete current layer if nearly done
2. Build and test current changes
3. Commit stable work
4. Update status documentation
5. Plan to stop before next major layer
```

#### Critical Threshold (<30k)
```
🚨 CRITICAL THRESHOLD (<30k tokens)

RECOMMENDED ACTION: STOP AND DOCUMENT

1. Stop current work immediately
2. Create/update status documentation
3. Commit any stable changes
4. Run session-end hook manually
5. Continue in fresh session

❌ DO NOT:
   - Start new layers/phases
   - Make large code changes
   - Leave code in broken state
```

---

### Session End (Manual or Automatic)

**Manual Trigger:**
```bash
bash .claude/end-session.sh
```

**Or tell Claude:**
> "Please run the session end hook"

**What Happens:**
1. Creates timestamped snapshot file with:
   - Git status
   - Recent commits (last 3)
   - Modified files
   - Build status
   - Next session checklist
2. Logs session end to session-history.log
3. Displays session summary
4. Shows next session instructions
5. Confirms context is preserved

**Output Example:**
```
═══════════════════════════════════════════════════════════════
🏁 SESSION END: October 22, 2025 16:45:00
═══════════════════════════════════════════════════════════════

📸 Session snapshot saved:
   .claude/session-end-snapshot-20251022-164500.md

📊 SESSION SUMMARY:

   Modified files: 2
   ⚠️  Status: UNCOMMITTED CHANGES

   💡 Action Required:
      - Review changes in next session
      - Complete work or commit if stable

📋 NEXT SESSION INSTRUCTIONS:

   1. Start with: Read POST-COMPRESSION-RESTORATION-PROMPT.md
   2. Then read: PHASE-v1.5-EXECUTION-STATUS.md
   3. Review session snapshot: session-end-snapshot-20251022-164500.md
   4. Check git status before proceeding
   5. Continue documented work

✅ Session ended cleanly. Context preserved!
```

---

## ⚙️ CONFIGURATION

**File:** `.claude/settings.json`

```json
{
  "hooks": {
    "onSessionStart": "bash .claude/hooks/session-start.sh",
    "onSessionEnd": "bash .claude/hooks/session-end.sh",
    "onTokenThreshold": "bash .claude/hooks/token-warning.sh"
  },
  "tokenThresholds": {
    "warning": 50000,
    "critical": 30000
  },
  "autoDocumentation": true,
  "sessionTracking": true
}
```

**Customization:**
- Change thresholds: Edit `tokenThresholds` values
- Disable hooks: Comment out hook entries
- Add custom hooks: Add new entries to `hooks` object

---

## 📖 USAGE GUIDE

### Starting a New Session

**Step 1:** Claude Code automatically runs `session-start.sh`

**Step 2:** You see context restoration checklist

**Step 3:** Tell Claude:
> "I've read the context. Let's continue from where we left off."

**Step 4:** Claude reads restoration prompt and status docs

**Step 5:** Work begins with full context

---

### During Active Work

**Monitor token warnings:**
- Claude will notify you at 50k and 30k thresholds
- Follow the recommended actions displayed

**If you see warning threshold:**
- Finish current layer
- Build + test + commit
- Update status docs
- Prepare to stop

**If you see critical threshold:**
- Stop immediately
- Document current state
- Run session end hook
- Continue in fresh session

---

### Ending a Session

**Option A: Manual End (Recommended)**
```bash
bash .claude/end-session.sh
```

**Option B: Tell Claude**
> "Please end the session cleanly and create a snapshot"

**What to do after:**
1. Review the snapshot file created
2. Confirm status docs are updated
3. Check git status (commit if appropriate)
4. Close Claude Code session confidently

---

## 🎓 BEST PRACTICES

### Do's ✅
- **Always run session start** hook at beginning of session
- **Read restoration prompt** before starting work
- **Monitor token warnings** and act on them
- **End sessions cleanly** using the end hook
- **Review snapshots** at start of next session
- **Commit stable work** before ending sessions
- **Update status docs** throughout session

### Don'ts ❌
- **Don't ignore token warnings** (they prevent broken states)
- **Don't skip restoration prompts** (context loss guaranteed)
- **Don't end sessions mid-layer** (unless critical threshold hit)
- **Don't leave uncommitted work** without documenting
- **Don't assume previous state** (always check git status)

---

## 🔍 MONITORING & LOGS

### Session History Log
**File:** `.claude/session-history.log`

**Contains:**
- All session starts (timestamp)
- All session ends (timestamp)
- Token warnings (when triggered)
- Files modified count
- Snapshot file references

**Example:**
```
SESSION START: 2025-10-22 14:30:00
TOKEN WARNING: 45000 tokens remaining at 2025-10-22 15:30:00
SESSION END: 2025-10-22 16:45:00
FILES MODIFIED: 2
SNAPSHOT: .claude/session-end-snapshot-20251022-164500.md
---
```

### Session Snapshots
**Pattern:** `.claude/session-end-snapshot-YYYYMMDD-HHMMSS.md`

**Contains:**
- Complete git status
- Recent commits
- Modified files list
- Build status
- Next session checklist

**Retention:** Keep last 10 snapshots, archive older ones

---

## 🛠️ TROUBLESHOOTING

### Hook Not Running

**Problem:** Session start hook didn't run

**Solution:**
```bash
# Manually run it:
bash .claude/hooks/session-start.sh

# Check permissions:
ls -la .claude/hooks/

# Fix permissions if needed:
chmod +x .claude/hooks/*.sh
```

---

### Token Warning Not Showing

**Problem:** Didn't see warning at threshold

**Solution:**
- Check `.claude/settings.json` thresholds
- Manually check token count
- Manually trigger warning:
```bash
bash .claude/hooks/token-warning.sh 45000 50000
```

---

### Snapshot Not Created

**Problem:** Session end didn't create snapshot

**Solution:**
```bash
# Manually run session end:
bash .claude/hooks/session-end.sh

# Check if snapshot was created:
ls -lt .claude/session-end-snapshot-*.md | head -1

# Check session log:
tail -20 .claude/session-history.log
```

---

## 📊 EFFECTIVENESS TRACKING

### Signs System Is Working ✅
- Session starts show context restoration checklist
- Token warnings appear at configured thresholds
- Snapshots created at session end
- Session log tracks all activity
- No context loss between sessions
- No broken code states
- Work resumes smoothly in fresh sessions

### Signs System Needs Attention ⚠️
- Context lost between sessions
- Token limits hit unexpectedly
- Code left in broken state
- Unclear what to do at session start
- Snapshots missing or incomplete
- Session log not updating

**Action:** Review and update hook scripts as needed

---

## 🔄 MAINTENANCE

### Weekly
- Review session-history.log for patterns
- Archive old snapshots (keep last 10)
- Verify hooks still executable

### Monthly
- Review token threshold effectiveness
- Update hook scripts if workflow changes
- Clean up old snapshot files

### As Needed
- Adjust token thresholds based on experience
- Add new hooks for project-specific needs
- Update documentation with lessons learned

---

## 🎯 SUCCESS METRICS

**This system is successful when:**
1. ✅ Zero context loss between sessions
2. ✅ Zero code left in broken states
3. ✅ Token usage optimized (no wasted work)
4. ✅ Clean handoffs between sessions
5. ✅ Clear action items at session start
6. ✅ Confidence in stopping/continuing work
7. ✅ Complete audit trail (logs + snapshots)

---

## 📞 HELP & SUPPORT

### Quick Commands
```bash
# Start session manually:
bash .claude/hooks/session-start.sh

# End session manually:
bash .claude/end-session.sh

# Check token warning:
bash .claude/hooks/token-warning.sh [token_count] [threshold]

# View session history:
tail -50 .claude/session-history.log

# List recent snapshots:
ls -lt .claude/session-end-snapshot-*.md | head -5
```

### Where to Get Help
- Review this README
- Check session-history.log for clues
- Review most recent snapshot file
- Read POST-COMPRESSION-RESTORATION-PROMPT.md

---

## 🎓 INDUSTRY LEADER VALIDATION

**This pattern follows:**

1. **Apple's Xcode Build Phases**
   - Pre-build, build, post-build hooks
   - Clean lifecycle management
   - Automatic dependency checks

2. **Google's Bazel**
   - Lifecycle hooks for build events
   - Automatic caching and state management
   - Reproducible build environments

3. **Git Hooks Standard**
   - pre-commit, post-commit lifecycle
   - Automatic code quality checks
   - State verification before operations

4. **CI/CD Pipeline Pattern**
   - Jenkins/GitHub Actions lifecycle
   - Automatic testing at boundaries
   - State snapshots for rollback

**Result:** Industry-standard session lifecycle management adapted for AI-assisted development

---

## 📝 VERSION HISTORY

**v1.0.0 - October 22, 2025**
- Initial release
- Session start/end hooks
- Token warning system
- Snapshot creation
- Session history logging

---

**Last Updated:** October 22, 2025
**Owner:** Rich Marin (Product Owner)
**Maintainer:** Claude Code Automation System
**Status:** Active and monitoring

---

**END OF SYSTEM DOCUMENTATION**
