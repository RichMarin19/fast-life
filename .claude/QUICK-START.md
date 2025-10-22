# Claude Code Session Management - Quick Start

## 🚀 NEW SESSION START

**What you'll see:**
- Automatic context restoration checklist
- Current phase status
- Git status check
- Token budget display

**What you do:**
1. Read the displayed checklist
2. Tell Claude: "I've read the context. Let's continue."
3. Start working

---

## ⚠️ TOKEN WARNING (50k remaining)

**What it means:**
- Finish current layer only
- Don't start new major work

**What you do:**
1. Complete current task
2. Build + test
3. Commit stable work
4. Prepare to stop

---

## 🚨 TOKEN CRITICAL (30k remaining)

**What it means:**
- STOP IMMEDIATELY
- Don't start anything new

**What you do:**
1. Tell Claude: "Please end this session cleanly"
2. Claude will create snapshot
3. Review snapshot
4. Close session
5. Start fresh next time

---

## 🏁 SESSION END (Manual)

**When to use:**
- Task complete
- Need to take a break
- Approaching token limit

**How to trigger:**
```bash
bash .claude/end-session.sh
```

**Or tell Claude:**
> "Please end the session and create a snapshot"

---

## 📋 NEXT SESSION (After ending)

**What to do:**
1. Start new Claude Code session
2. Wait for automatic context restoration
3. Tell Claude: "I've read the context. Continue from last session."
4. Claude reads snapshot and status docs
5. Work resumes with full context

---

## 🆘 QUICK COMMANDS

```bash
# View session history:
tail -20 .claude/session-history.log

# List recent snapshots:
ls -lt .claude/session-end-snapshot-*.md | head -3

# Manual session start:
bash .claude/hooks/session-start.sh

# Manual session end:
bash .claude/end-session.sh
```

---

**For full documentation:** See `.claude/README.md`
