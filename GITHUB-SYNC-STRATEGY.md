# GitHub Sync Strategy - Fast LIFe Project

> **Purpose:** Comprehensive strategy for synchronizing Desktop source of truth (v2.3.0) with GitHub fast-life repository (v1.1.4)
>
> **Last Updated:** October 16, 2025
>
> **Status:** Ready to execute after Phase B completion

---

## 📊 CURRENT STATE ASSESSMENT

### Desktop (Source of Truth)
- **Location:** `/Users/richmarin/Desktop/FastingTracker`
- **Version:** 2.3.0 (Build 12)
- **Build Status:** ✅ 0 errors, 0 warnings
- **Last Major Update:** Phase B - Behavioral Notification System (October 2025)
- **Key Features:**
  - Behavioral notification system (NEW)
  - Weight tracker refactored (257 LOC - GOLD STANDARD)
  - Mood tracker refactored (97 LOC)
  - HealthKit bidirectional sync
  - Hub navigation
  - Design system implemented

### GitHub Repository (fast-life)
- **URL:** https://github.com/[username]/fast-life
- **Last Known Version:** 1.1.4 (Build 6)
- **Last Sync:** Pre-Phase B (estimated)
- **Version Gap:** 12 versions behind (2.3.0 Build 12 vs 1.1.4 Build 6)

---

## 🎯 SYNC OBJECTIVES

### Primary Goals
1. ✅ Bring GitHub repository to parity with Desktop (v2.3.0 Build 12)
2. ✅ Preserve Git history for future collaboration
3. ✅ Tag Phase B completion milestone (v2.3.0-phase-b-complete)
4. ✅ Establish Phase C branch strategy
5. ✅ Document sync process for future updates

### Success Criteria
- ✅ GitHub repo matches Desktop codebase exactly
- ✅ All 4 HANDOFF documentation files synced
- ✅ Version numbers aligned (Info.plist updated)
- ✅ Build succeeds on GitHub with 0 errors, 0 warnings
- ✅ Git tags created for Phase B milestone
- ✅ README updated with current project status

---

## 🚀 RECOMMENDED SYNC STRATEGY

### Strategy: **OPTION 2 - Incremental Commit Approach** (RECOMMENDED)

**Why This Strategy:**
- ✅ Preserves Git history for future reference
- ✅ Allows granular tracking of changes
- ✅ Easier to review and roll back if needed
- ✅ Industry standard (Apple, Google, Meta all use incremental commits)
- ✅ Provides clear documentation trail

**Alternative (Not Recommended):**
- ❌ **OPTION 1 - Force Push:** Overwrites Git history, loses context
- Why Not: Destroys valuable historical information, makes debugging harder

---

## 📋 PHASE B SYNC CHECKLIST (Step-by-Step)

### Pre-Sync Verification (5 minutes)

**Desktop Verification:**
- [ ] Confirm Desktop build succeeds (0 errors, 0 warnings)
- [ ] Verify version in Info.plist: 2.3.0 (Build 12)
- [ ] Confirm all HANDOFF*.md files exist and are current
- [ ] Check ROADMAP.md is up to date

**GitHub Verification:**
- [ ] Confirm GitHub credentials configured
- [ ] Test GitHub connection: `git remote -v`
- [ ] Verify write access to repository
- [ ] Check current branch (should be `main` or `master`)

---

### STEP 1: Initialize Git Repository (if needed) - 5 minutes

**If Desktop is NOT a Git repository:**

```bash
cd /Users/richmarin/Desktop/FastingTracker

# Initialize Git
git init

# Add GitHub remote
git remote add origin https://github.com/[username]/fast-life.git

# Fetch GitHub repository state
git fetch origin

# Check existing branches
git branch -a
```

**If Desktop IS already a Git repository:**

```bash
cd /Users/richmarin/Desktop/FastingTracker

# Verify remote
git remote -v

# Fetch latest from GitHub
git fetch origin

# Check current branch
git branch
```

---

### STEP 2: Create Phase B Completion Branch - 2 minutes

```bash
# Create and switch to Phase B branch
git checkout -b phase-b-completion-v2.3.0

# Verify you're on correct branch
git branch
# Should show: * phase-b-completion-v2.3.0
```

---

### STEP 3: Stage Changes by Category - 15 minutes

**Commit Strategy:** Group related changes into logical commits

#### Commit 1: Documentation Updates

```bash
# Stage new documentation structure
git add HANDOFF.md
git add HANDOFF-HISTORICAL.md
git add HANDOFF-PHASE-C.md
git add HANDOFF-REFERENCE.md
git add GITHUB-SYNC-STRATEGY.md

# Commit with descriptive message
git commit -m "$(cat <<'EOF'
docs: Split HANDOFF.md into focused documentation files

Following Industry Standards (Apple, Google, Meta) for documentation organization:
- HANDOFF.md: Main index with navigation (378 lines)
- HANDOFF-HISTORICAL.md: Completed phases archive (1,278 lines)
- HANDOFF-PHASE-C.md: Active Phase C work (434 lines)
- HANDOFF-REFERENCE.md: Timeless best practices (913 lines)
- GITHUB-SYNC-STRATEGY.md: Repository sync procedures

Total: 2,531 lines → 3,003 lines (added 472 lines of navigation)

🤖 Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)"
```

#### Commit 2: Behavioral Notification System

```bash
# Stage notification system files
git add FastingTracker/Core/Managers/NotificationManager.swift
git add FastingTracker/Core/Managers/NotificationIdentifierBuilder.swift
git add FastingTracker/Core/Managers/BehavioralNotificationScheduler_Simple.swift
git add FastingTracker/Core/Notifications/BehavioralNotificationRule.swift
git add FastingTracker/Core/Notifications/TrackerNotificationRules.swift

# Commit
git commit -m "$(cat <<'EOF'
feat: Add behavioral notification system (Phase B)

Implemented comprehensive notification system following Apple HIG:
- NotificationManager: Central orchestration
- NotificationIdentifierBuilder: Identifier utility (Task #6)
- BehavioralNotificationScheduler: Simplified scheduler
- Tracker-specific notification rules (Fasting, Hydration, Sleep)

Key achievements:
- Zero build errors/warnings
- Apple-compliant notification patterns
- Granular per-tracker control
- Expert Panel Task #6 complete

🤖 Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)"
```

#### Commit 3: Build System Modernization

```bash
# Stage Xcode project configuration
git add FastingTracker.xcodeproj/project.pbxproj

# Commit
git commit -m "$(cat <<'EOF'
build: Modernize Xcode build system to 16.2

Updates:
- LastUpgradeCheck: 1640 → 2600
- STRING_CATALOG_GENERATE_SYMBOLS enabled
- NotificationIdentifierBuilder.swift registered in project
- File path corrections (Core/Managers/ structure)

Resolves:
- "Build input file cannot be found" errors
- "Cannot find type in scope" errors
- Duplicate type declaration issues

🤖 Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)"
```

#### Commit 4: Version Bump & Phase B Completion

```bash
# Stage version files
git add FastingTracker/Info.plist

# Commit
git commit -m "$(cat <<'EOF'
chore: Bump version 2.2.0 Build 9 → 2.3.0 Build 12

Phase B - Behavioral Notification System: COMPLETE ✅

Key metrics:
- Build status: 0 errors, 0 warnings
- LOC baseline: 1,894 lines (4 trackers pending refactor)
- Phase C ready to start

Definition of Done:
✅ Build succeeds with 0 errors, 0 warnings
✅ Behavioral system operational
✅ Xcode modernized
✅ Documentation reorganized

Next phase: Phase C - Tracker Rollout
- Sleep: 304 LOC → 300 LOC (LOW RISK)
- Hydration: 584 LOC → 300 LOC (MEDIUM RISK)
- Fasting: 652 LOC → 300 LOC (HIGH RISK)

🤖 Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)"
```

---

### STEP 4: Push to GitHub & Create Pull Request - 5 minutes

```bash
# Push branch to GitHub
git push -u origin phase-b-completion-v2.3.0

# Command output should confirm successful push
```

**Then create Pull Request on GitHub:**
1. Go to https://github.com/[username]/fast-life
2. Click "Compare & pull request" for `phase-b-completion-v2.3.0`
3. Title: "Phase B Complete: Behavioral Notification System v2.3.0"
4. Description:

```markdown
## Phase B - Behavioral Notification System (COMPLETE)

**Version:** 2.3.0 (Build 12)
**Status:** ✅ Production Ready

### Key Achievements
- Behavioral notification system implemented
- Build system modernized (Xcode 16.2)
- Documentation reorganized (Industry Standards)
- Zero build errors/warnings

### Files Changed
- **Notification System:** 5 new files
- **Build Configuration:** project.pbxproj updated
- **Documentation:** Split into 4 focused files (2,531 → 3,003 lines)
- **Version:** Info.plist (2.3.0 Build 12)

### Testing Completed
- ✅ Build succeeds with 0 errors, 0 warnings
- ✅ Notification scheduling operational
- ✅ Xcode project configuration valid
- ✅ All existing features preserved

### Next Steps
Phase C - Tracker Rollout (1,894 LOC → 1,200 LOC)

See [HANDOFF-PHASE-C.md](./HANDOFF-PHASE-C.md) for details.

🤖 Generated with Claude Code
```

5. Click "Create pull request"
6. **Review changes carefully** before merging
7. Merge PR to `main` branch

---

### STEP 5: Tag Phase B Completion - 2 minutes

**After merging PR:**

```bash
# Switch to main branch
git checkout main

# Pull latest changes
git pull origin main

# Create annotated tag
git tag -a v2.3.0-phase-b-complete -m "$(cat <<'EOF'
Phase B Complete: Behavioral Notification System

Version: 2.3.0 (Build 12)
Date: October 2025

Key Features:
- Behavioral notification system
- NotificationIdentifierBuilder utility
- Build system modernized (Xcode 16.2)
- Documentation reorganized (4 focused files)

Build Status: ✅ 0 errors, 0 warnings

Definition of Done: ACHIEVED ✅

Next: Phase C - Tracker Rollout
EOF
)"

# Push tag to GitHub
git push origin v2.3.0-phase-b-complete

# Verify tag created
git tag -l
```

---

### STEP 6: Create Phase C Branch - 1 minute

```bash
# Create Phase C branch from main
git checkout -b phase-c-tracker-rollout

# Push branch to GitHub
git push -u origin phase-c-tracker-rollout

# Switch back to main
git checkout main
```

---

## 🎯 POST-SYNC VERIFICATION (5 minutes)

### GitHub Verification Checklist

**On GitHub Web:**
- [ ] Verify main branch shows v2.3.0 (Build 12) in Info.plist
- [ ] Confirm all HANDOFF*.md files visible
- [ ] Check commit history shows 4 logical commits
- [ ] Verify tag `v2.3.0-phase-b-complete` exists
- [ ] Confirm branch `phase-c-tracker-rollout` created
- [ ] README.md updated (if applicable)

**Clone Fresh Copy Test:**

```bash
# Clone to temporary location
cd ~/Desktop
git clone https://github.com/[username]/fast-life.git fast-life-test

# Verify version
cd fast-life-test
cat FastingTracker/Info.plist | grep -A1 "CFBundleShortVersionString"
# Should show: 2.3.0

cat FastingTracker/Info.plist | grep -A1 "CFBundleVersion"
# Should show: 12

# Open in Xcode
open FastingTracker.xcodeproj

# Build project (Cmd+B)
# Expected: ✅ Build Succeeded with 0 errors, 0 warnings

# Clean up
cd ~/Desktop
rm -rf fast-life-test
```

---

## 📚 FUTURE SYNC PROTOCOL

### When to Sync Desktop → GitHub

**Required Sync Events:**
1. **Phase Completion** (after Phase C, D, etc.)
2. **Version Bumps** (any Info.plist version change)
3. **Major Features** (significant functionality additions)
4. **Critical Fixes** (bug fixes affecting user experience)

**Recommended Frequency:**
- Minimum: After each completed phase
- Ideal: Weekly during active development
- Maximum interval: 2 weeks (prevents large diffs)

### Quick Sync Checklist

**Before Sync:**
- [ ] Build succeeds on Desktop (0 errors, 0 warnings)
- [ ] All tests pass (manual + automated)
- [ ] Documentation updated (HANDOFF files current)
- [ ] Version number bumped (if applicable)

**During Sync:**
- [ ] Create descriptive branch name
- [ ] Group commits logically (not one giant commit)
- [ ] Write clear commit messages
- [ ] Include Claude Code footer

**After Sync:**
- [ ] Create pull request with summary
- [ ] Review changes before merging
- [ ] Tag milestones (version releases, phase completions)
- [ ] Verify fresh clone builds successfully

---

## 🛡️ ROLLBACK STRATEGY

### If Sync Goes Wrong

**Scenario 1: Bad commit on branch (not merged)**

```bash
# Reset branch to previous commit
git reset --hard HEAD~1

# Force push to GitHub (safe because not merged)
git push -f origin phase-b-completion-v2.3.0
```

**Scenario 2: Bad merge to main**

```bash
# Find commit hash before merge
git log --oneline

# Revert merge commit
git revert -m 1 <merge-commit-hash>

# Push revert
git push origin main
```

**Scenario 3: Nuclear option (complete reset)**

```bash
# Create backup first!
cp -r /Users/richmarin/Desktop/FastingTracker ~/Desktop/FastingTracker-backup

# Force push Desktop state to GitHub
cd /Users/richmarin/Desktop/FastingTracker
git push --force origin main

# WARNING: This destroys GitHub history - only use as last resort!
```

---

## 📖 GIT COMMANDS REFERENCE

### Essential Commands

```bash
# Check repository status
git status

# View commit history
git log --oneline --graph --decorate --all

# View pending changes
git diff

# View staged changes
git diff --staged

# List all branches
git branch -a

# List all tags
git tag -l

# View remote configuration
git remote -v

# Fetch without merging
git fetch origin

# Pull latest changes
git pull origin main

# Stash uncommitted changes
git stash
git stash pop
```

### Troubleshooting Commands

```bash
# Discard uncommitted changes
git checkout -- <file>

# Unstage file
git reset HEAD <file>

# Undo last commit (keep changes)
git reset --soft HEAD~1

# View file in specific commit
git show <commit-hash>:<file-path>

# Compare branches
git diff main..phase-b-completion-v2.3.0

# Check file history
git log --follow <file>
```

---

## 🤝 COLLABORATION WORKFLOW

### For Future Team Members

**If multiple developers work on Fast LIFe:**

1. **Always create feature branches**
   ```bash
   git checkout -b feature/my-feature-name
   ```

2. **Pull latest before starting work**
   ```bash
   git checkout main
   git pull origin main
   git checkout -b feature/my-feature
   ```

3. **Commit frequently with clear messages**
   ```bash
   git commit -m "feat: Add heart rate tracking to Sleep tracker"
   ```

4. **Create PR for review before merging**
   - Never push directly to `main`
   - Require at least 1 review
   - Run build verification

5. **Keep branches short-lived**
   - Merge within 2-3 days
   - Delete after merging
   - Prevents merge conflicts

---

## 📝 COMMIT MESSAGE STANDARDS

### Format (Conventional Commits)

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types
- **feat:** New feature
- **fix:** Bug fix
- **docs:** Documentation only
- **style:** Code style (formatting, missing semi-colons)
- **refactor:** Code change (neither fixes bug nor adds feature)
- **test:** Adding or updating tests
- **chore:** Maintenance (dependencies, build config)
- **build:** Build system or external dependencies
- **ci:** CI/CD configuration

### Examples

```bash
# New feature
git commit -m "feat(fasting): Add behavioral notifications for fasting stages"

# Bug fix
git commit -m "fix(weight): Correct BMI calculation for metric units"

# Documentation
git commit -m "docs: Split HANDOFF.md into 4 focused files"

# Refactor
git commit -m "refactor(hydration): Extract HydrationTimerView component (584→250 LOC)"

# Build system
git commit -m "build: Upgrade Xcode to 16.2, enable string catalog generation"
```

---

## 🎯 PHASE C SYNC PREVIEW

### After Phase C Completion

**Expected commits:**
1. `refactor(sleep): Extract Sleep components (304→250 LOC)` - Phase C.1
2. `refactor(hydration): Extract Hydration components (584→250 LOC)` - Phase C.2
3. `refactor(fasting): Extract Fasting components (652→250 LOC)` - Phase C.3
4. `chore: Bump version 2.3.0 Build 12 → 2.4.0 Build 13` - Version bump
5. `docs: Update HANDOFF files with Phase C completion` - Documentation

**Tag:** `v2.4.0-phase-c-complete`

**Branch:** `phase-d-[next-phase-name]`

---

## 🚨 CRITICAL REMINDERS

### NEVER Do These Things

❌ **Force push to `main` branch** (unless absolute emergency)
❌ **Commit sensitive data** (.env files, API keys, credentials)
❌ **Commit Xcode user data** (xcuserdata/, .DS_Store)
❌ **Commit large binary files** (use Git LFS if needed)
❌ **Rewrite public history** (commits that others have pulled)

### ALWAYS Do These Things

✅ **Review changes before committing** (`git diff`)
✅ **Write clear commit messages** (explain WHY, not just WHAT)
✅ **Build successfully before pushing** (0 errors, 0 warnings)
✅ **Update documentation** (keep HANDOFF files current)
✅ **Tag version milestones** (phases, releases)

---

## 📞 SUPPORT & RESOURCES

### If You Get Stuck

1. **Check Git status first:** `git status`
2. **Review this document:** GITHUB-SYNC-STRATEGY.md
3. **Search Git documentation:** https://git-scm.com/doc
4. **Ask for help:** Include `git status` output and error messages

### Useful Resources

- **Git Documentation:** https://git-scm.com/doc
- **GitHub Guides:** https://guides.github.com/
- **Conventional Commits:** https://www.conventionalcommits.org/
- **Git Best Practices:** https://sethrobertson.github.io/GitBestPractices/
- **Apple Git Guidelines:** (Internal Apple documentation)

---

**Last Updated:** October 16, 2025
**Next Review:** After Phase C completion
**Status:** Ready for Phase B sync execution
