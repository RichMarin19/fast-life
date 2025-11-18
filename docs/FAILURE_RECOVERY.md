# 🆘 Failure Recovery Guide

**How to rollback when things go wrong**

---

## 📋 Overview

**Purpose:** Quick recovery procedures to minimize downtime and data loss.

**Why this matters:**
- Mistakes happen (especially during complex transformations)
- Fast recovery = less stress
- Documented procedures = confidence to experiment
- Version control = safety net

**Golden Rule:** **Commit early, commit often. Can't rollback what wasn't committed.**

---

## 🚨 Emergency Quick Reference

| Scenario | Immediate Action | Recovery Time |
|----------|-----------------|---------------|
| [App won't build](#1-app-wont-build) | `git reset --hard HEAD` | 1 min |
| [All tests failing](#2-all-tests-failing) | `git bisect` to find bad commit | 10 min |
| [Broke production app](#3-broke-production-app) | Revert commit, hotfix release | 30 min |
| [Lost uncommitted work](#4-lost-uncommitted-work) | Check .swiftpm, DerivedData | 15 min |
| [Corrupted git repo](#5-corrupted-git-repo) | `git fsck`, clone fresh | 20 min |
| [SwiftData migration failed](#6-swiftdata-migration-failed) | Rollback schema, delete app | 10 min |
| [Deleted wrong files](#7-deleted-wrong-files) | `git checkout HEAD -- <file>` | 2 min |
| [Pushed secrets to GitHub](#8-pushed-secrets-to-github) | Revoke secrets, rewrite history | 30 min |
| [Dependency hell](#9-dependency-hell) | Delete Package.resolved, clean | 10 min |
| [Merge conflict disaster](#10-merge-conflict-disaster) | `git merge --abort`, redo carefully | 20 min |

---

## 1. App Won't Build

### Symptoms
- Build errors everywhere
- "Command SwiftCompile failed"
- Can't find packages/modules
- "No such module 'Core'"

### Emergency Recovery

**Option A: Rollback to last working commit (fastest)**
```bash
# WARNING: Loses all uncommitted changes
git status  # Check what you'll lose
git stash   # Save changes for later (if valuable)
git reset --hard HEAD  # Reset to last commit

# Clean build
rm -rf ~/Library/Developer/Xcode/DerivedData
xcodebuild clean -workspace FastingTracker.xcworkspace -scheme FastingTracker
xcodebuild build -workspace FastingTracker.xcworkspace -scheme FastingTracker
```

**Option B: Rollback to specific commit**
```bash
# Find last working commit
git log --oneline  # Find commit hash

# Reset to that commit
git reset --hard abc123  # Replace abc123 with hash

# Clean and rebuild
rm -rf ~/Library/Developer/Xcode/DerivedData
xcodebuild clean build -workspace FastingTracker.xcworkspace -scheme FastingTracker
```

**Option C: Undo specific file changes**
```bash
# Identify problem file
# Usually shown in build error

# Reset just that file
git checkout HEAD -- FastingTracker/Problem.swift

# Rebuild
xcodebuild build -workspace FastingTracker.xcworkspace -scheme FastingTracker
```

### Prevention
- ✅ Commit after each working feature
- ✅ Test build before committing
- ✅ Use feature branches (easy to delete if broken)
- ✅ Push to remote frequently (backup)

---

## 2. All Tests Failing

### Symptoms
- Tests that passed before now fail
- Multiple test failures after recent changes
- Can't identify which change broke tests

### Emergency Recovery

**Option A: Git bisect (find bad commit)**
```bash
# Start bisect
git bisect start

# Mark current as bad
git bisect bad

# Mark last known good commit
git log --oneline  # Find good commit
git bisect good abc123  # Replace with hash

# Git will checkout commits
# Run tests at each step
xcodebuild test -workspace FastingTracker.xcworkspace -scheme FastingTracker

# Mark each as good or bad
git bisect good  # If tests pass
git bisect bad   # If tests fail

# Git identifies the problematic commit
# Review and fix that specific change

# End bisect
git bisect reset
```

**Option B: Rollback and reapply changes carefully**
```bash
# Save current changes
git stash

# Rollback to working state
git reset --hard <last-good-commit>

# Verify tests pass
xcodebuild test -workspace FastingTracker.xcworkspace -scheme FastingTracker

# Reapply changes one file at a time
git stash show -p | head -n 50  # View changes
# Manually reapply, testing after each file
```

**Option C: Run specific failing test to debug**
```bash
# Run single failing test
xcodebuild test \
  -workspace FastingTracker.xcworkspace \
  -scheme FastingTracker \
  -only-testing:FastingTrackerTests/FastingRepositoryTests/testStartFasting

# Add print statements to debug
# Fix the specific issue
```

### Prevention
- ✅ Run tests before every commit (git hooks)
- ✅ Keep commits small (easy to rollback)
- ✅ Write tests as you go (not at end)
- ✅ Fix failing tests immediately

---

## 3. Broke Production App

### Symptoms
- App crashes on launch
- Critical feature broken
- Users reporting issues
- Urgent fix needed

### Emergency Recovery

**Option A: Revert problematic commit**
```bash
# Identify bad commit
git log --oneline

# Create revert commit
git revert abc123  # Replace with bad commit hash

# This creates a new commit that undoes the changes

# Test the revert
xcodebuild test -workspace FastingTracker.xcworkspace -scheme FastingTracker

# Push revert
git push origin main
```

**Option B: Hotfix from last good release**
```bash
# Create hotfix branch from last good tag
git checkout -b hotfix/critical-crash phase-1-complete

# Make minimal fix
# Edit only necessary files

# Test fix
xcodebuild test -workspace FastingTracker.xcworkspace -scheme FastingTracker

# Commit hotfix
git commit -am "hotfix: fix critical crash in sleep tracking"

# Tag hotfix
git tag v1.0.1
git push origin hotfix/critical-crash
git push origin v1.0.1

# Deploy hotfix
./scripts/deploy_testflight.sh

# Merge hotfix back to main
git checkout main
git merge hotfix/critical-crash
git push origin main
```

**Option C: Emergency rollback to previous TestFlight build**
```
1. Log in to App Store Connect
2. TestFlight > Builds
3. Select previous working build
4. Add to testing groups
5. Notify testers of rollback
6. Fix issue in code
7. Submit new build
```

### Prevention
- ✅ Test on device before releasing
- ✅ Use TestFlight beta testing
- ✅ Monitor crash reports (Firebase)
- ✅ Keep main branch always releasable
- ✅ Tag every release (easy rollback point)

---

## 4. Lost Uncommitted Work

### Symptoms
- Accidentally reset/deleted changes
- Work not committed
- Xcode crashed and lost changes
- Deleted file that wasn't committed

### Emergency Recovery

**Option A: Check git reflog (uncommitted changes)**
```bash
# Git tracks everything, even resets
git reflog

# Find your lost commit
# Shows: abc123 HEAD@{1}: commit: WIP sleep tracking

# Restore that state
git checkout abc123

# Or create branch from it
git checkout -b recovery abc123
```

**Option B: Search for file in build artifacts**
```bash
# Xcode sometimes keeps copies
find ~/Library/Developer/Xcode/DerivedData -name "SleepRepository.swift" -mtime -1

# Check .swiftpm
find .swiftpm -name "*.swift" -mtime -1
```

**Option C: Use Time Machine (macOS)**
```
1. Open Time Machine
2. Navigate to project directory
3. Find timestamp before loss
4. Restore specific files
```

**Option D: Check local snapshots (macOS)**
```bash
# List snapshots
tmutil listlocalsnapshots /

# Mount snapshot
tmutil mount com.apple.TimeMachine.2025-10-27-120000.local

# Copy files
cp /Volumes/snapshot/Users/richmarin/fast-life/Problem.swift .
```

### Prevention
- ✅ **COMMIT FREQUENTLY** (every 30-60 min)
- ✅ Use `git stash` before risky operations
- ✅ Enable Time Machine backups
- ✅ Push to remote regularly
- ✅ Use auto-save in Xcode

---

## 5. Corrupted Git Repo

### Symptoms
- "fatal: corrupt object"
- "error: object file is empty"
- Git commands fail

### Emergency Recovery

**Option A: Repair git database**
```bash
# Try to fix
git fsck --full

# Remove corrupt objects
find .git/objects/ -size 0 -delete

# Recover from remote
git fetch origin
git reset --hard origin/main
```

**Option B: Clone fresh copy**
```bash
# Backup current (might have uncommitted work)
mv fast-life fast-life-backup

# Clone fresh
git clone https://github.com/yourusername/fast-life.git

cd fast-life

# Copy any uncommitted files from backup
cp -r ../fast-life-backup/FastingTracker/NewFeature.swift FastingTracker/
```

**Option C: Rebuild from scratch (worst case)**
```bash
# Remove .git directory
rm -rf .git

# Reinitialize
git init
git remote add origin https://github.com/yourusername/fast-life.git

# Fetch history
git fetch origin main

# Reset to remote
git reset --hard origin/main
```

### Prevention
- ✅ Push to remote frequently (GitHub = backup)
- ✅ Don't manually edit .git/ directory
- ✅ Use `git gc` occasionally to clean up
- ✅ Keep Time Machine backups

---

## 6. SwiftData Migration Failed

### Symptoms
- "Failed to load ModelContainer"
- App crashes on launch after schema change
- "NSPersistentStoreCoordinator with no persistent stores"

### Emergency Recovery

**Option A: Delete app and rebuild (Development)**
```bash
# Delete app from simulator/device
# Or:
xcrun simctl uninstall booted com.fastlife.app

# Clean build folder
rm -rf ~/Library/Developer/Xcode/DerivedData

# Rebuild
xcodebuild clean build -workspace FastingTracker.xcworkspace -scheme FastingTracker

# Test data will be lost (expected in dev)
```

**Option B: Rollback schema changes**
```bash
# Revert model changes
git diff HEAD~1 -- "**/Models/*.swift"  # View changes

git checkout HEAD~1 -- FastingTracker/Models/SleepEntry.swift

# Rebuild
xcodebuild clean build -workspace FastingTracker.xcworkspace -scheme FastingTracker
```

**Option C: Implement migration (Production)**
```swift
// Create migration plan (see PHASE_1_ARCHITECTURE_COMPLETE.md)
let migrationPlan = SchemaMigrationPlan(
    schemas: [FastLifeSchemaV1.self, FastLifeSchemaV2.self],
    stages: [
        MigrationStage.lightweight(fromVersion: FastLifeSchemaV1.self, toVersion: FastLifeSchemaV2.self)
    ]
)

let container = try ModelContainer(
    for: FastLifeSchemaV2.self,
    migrationPlan: migrationPlan
)
```

### Prevention
- ✅ Test schema changes in clean install first
- ✅ Write migration tests
- ✅ Use versioned schemas for production
- ✅ Backup data before schema changes

---

## 7. Deleted Wrong Files

### Symptoms
- Accidentally deleted important file
- `rm -rf` went too far
- Deleted package directory

### Emergency Recovery

**Option A: Restore from git (if committed)**
```bash
# Check if file was committed
git log -- path/to/deleted/file.swift

# Restore from last commit
git checkout HEAD -- path/to/deleted/file.swift

# Or from specific commit
git checkout abc123 -- path/to/deleted/file.swift
```

**Option B: Restore from stash**
```bash
# List stashes
git stash list

# View stash contents
git stash show -p stash@{0}

# Apply stash
git stash apply stash@{0}
```

**Option C: Restore from Time Machine**
```
1. Open Time Machine
2. Navigate to project
3. Find deleted file
4. Restore
```

### Prevention
- ✅ Use git rm instead of rm (trackable)
- ✅ Commit before bulk deletions
- ✅ Use trash instead of rm -rf
- ✅ Alias rm to safer alternative:
```bash
# Add to ~/.zshrc
alias rm='trash'  # Requires: brew install trash
```

---

## 8. Pushed Secrets to GitHub

### Symptoms
- API key in commit history
- Password in pushed code
- Certificate in repository
- GitHub secret scanning alert

### Emergency Recovery

**CRITICAL: Act within minutes. Secrets are compromised immediately.**

**Step 1: Revoke compromised secrets (within 5 minutes)**
```bash
# Revoke API keys immediately
# Firebase: Console > Project Settings > Service accounts > Revoke
# Apple: Developer Portal > Certificates > Revoke

# Change passwords immediately
# Generate new API keys immediately
```

**Step 2: Remove from git history**
```bash
# Use BFG Repo Cleaner (faster than git filter-branch)
brew install bfg

# Clone mirror
git clone --mirror https://github.com/yourusername/fast-life.git

cd fast-life.git

# Remove sensitive file
bfg --delete-files GoogleService-Info.plist

# Clean up
git reflog expire --expire=now --all
git gc --prune=now --aggressive

# Force push (⚠️ DESTRUCTIVE)
git push --force

cd ..
rm -rf fast-life.git

# Re-clone clean repo
git clone https://github.com/yourusername/fast-life.git
```

**Step 3: Add to .gitignore**
```bash
# Add to .gitignore
echo "GoogleService-Info.plist" >> .gitignore
echo "*.pem" >> .gitignore
echo "*.p12" >> .gitignore
echo ".env" >> .gitignore

git add .gitignore
git commit -m "security: add secrets to gitignore"
git push
```

**Step 4: Notify team (if applicable)**
```
1. Alert all developers
2. Everyone must re-clone repository
3. Old clones have compromised secrets
```

### Prevention
- ✅ Add secrets to .gitignore FIRST
- ✅ Use environment variables for secrets
- ✅ Use git hooks to block secrets:
```bash
# Install git-secrets
brew install git-secrets

# Set up
cd /Users/richmarin/fast-life
git secrets --install
git secrets --register-aws
git secrets --add 'API[_-]?KEY.*[=:].*[0-9a-zA-Z]{20,}'
```
- ✅ Review commits before pushing
- ✅ Enable GitHub secret scanning

---

## 9. Dependency Hell

### Symptoms
- Package.resolved conflicts
- "Package graph is unresolvable"
- Circular dependencies
- Version conflicts

### Emergency Recovery

**Option A: Reset package resolution**
```bash
# Delete package artifacts
rm -rf .swiftpm
rm Package.resolved
rm -rf ~/Library/Developer/Xcode/DerivedData

# Reset package cache
# Xcode > File > Packages > Reset Package Caches

# Resolve packages fresh
xcodebuild -workspace FastingTracker.xcworkspace -scheme FastingTracker -resolvePackageDependencies

# Rebuild
xcodebuild clean build -workspace FastingTracker.xcworkspace -scheme FastingTracker
```

**Option B: Rollback Package.swift**
```bash
# View recent changes
git log --oneline -- Package.swift "**/Package.swift"

# Rollback to working version
git checkout abc123 -- Packages/Core/Package.swift

# Resolve again
xcodebuild -resolvePackageDependencies
```

**Option C: Fix circular dependencies**
```swift
// Identify cycle
// Example: Core → DesignSystem → Core

// Break cycle by moving shared types
// Move shared types to separate package

// Create SharedTypes package
// Core depends on SharedTypes
// DesignSystem depends on SharedTypes
// No cycle!
```

### Prevention
- ✅ Keep dependencies minimal
- ✅ Document package dependency graph
- ✅ Pin versions for stability
- ✅ Test after each dependency change

---

## 10. Merge Conflict Disaster

### Symptoms
- Merge conflicts in many files
- Conflict resolution broke code
- Tests failing after merge
- Build broken after merge

### Emergency Recovery

**Option A: Abort merge and redo carefully**
```bash
# Abort failed merge
git merge --abort

# Go back to clean state
git status  # Should be clean

# Try merge again, one file at a time
git merge feature-branch --no-commit --no-ff

# Review conflicts carefully
git status

# Resolve each conflict
# Test after each resolution
xcodebuild test -workspace FastingTracker.xcworkspace -scheme FastingTracker

# Commit when all resolved
git commit
```

**Option B: Use "ours" or "theirs" strategy**
```bash
# Accept all changes from feature branch
git checkout --theirs .
git add .

# Or accept all changes from main
git checkout --ours .
git add .

# Then manually review important changes
git diff main..feature-branch
```

**Option C: Cherry-pick commits instead**
```bash
# Abort merge
git merge --abort

# Cherry-pick commits one by one
git log feature-branch --oneline

git cherry-pick abc123  # First commit
# Test
git cherry-pick def456  # Second commit
# Test
# Repeat, testing after each
```

### Prevention
- ✅ Keep feature branches short-lived
- ✅ Merge main into feature regularly
- ✅ Use small, focused commits
- ✅ Pull before starting work
- ✅ Communicate with team about file changes

---

## 🎯 General Recovery Principles

### Before Recovery
1. **Don't panic** - Take 5 minutes to think
2. **Assess damage** - What exactly is broken?
3. **Check backups** - Git commits, Time Machine, remote
4. **Test in isolation** - Clone repo to test recovery
5. **Document what happened** - For future reference

### During Recovery
1. **One step at a time** - Don't make it worse
2. **Test after each step** - Verify fix worked
3. **Keep original copy** - Until recovery confirmed
4. **Ask for help** - After 30 min if stuck
5. **Document steps** - For others (and future you)

### After Recovery
1. **Understand root cause** - Why did it happen?
2. **Update prevention** - Add checks/hooks
3. **Share learnings** - Update this document
4. **Test prevention** - Verify it won't happen again
5. **Celebrate survival** - You handled it! 🎉

---

## 🆘 When All Else Fails

### Nuclear Option: Start Fresh (Last Resort)

**Only use when:**
- Repository completely corrupted
- Can't recover any other way
- Lost >8 hours trying to fix

**Procedure:**
```bash
# 1. Backup everything
cp -r ~/fast-life ~/fast-life-backup-$(date +%Y%m%d)

# 2. Clone fresh from GitHub
cd ~
mv fast-life fast-life-broken
git clone https://github.com/yourusername/fast-life.git

# 3. Copy uncommitted work from broken copy
cd fast-life
cp -r ../fast-life-broken/NewFeature FastingTracker/

# 4. Test everything
xcodebuild test -workspace FastingTracker.xcworkspace -scheme FastingTracker

# 5. Commit recovered work
git add .
git commit -m "recover: restore work from corrupted repo"
git push

# 6. Delete broken copy after confirming everything works
# Wait 1 week, then:
# rm -rf ~/fast-life-broken
```

---

## 📞 Getting Help

**If stuck >30 minutes:**

1. **Search this document** - Ctrl+F your error
2. **Search TROUBLESHOOTING.md** - Common issues
3. **Google exact error message**
4. **Search Stack Overflow**
5. **Check GitHub issues** for dependencies
6. **Ask on Swift Forums**
7. **Ask on Discord/Slack** (iOS dev communities)

**When asking for help:**
- ✅ Describe what you were trying to do
- ✅ Show exact error message
- ✅ Share relevant code
- ✅ List what you've already tried
- ✅ Be patient and respectful

---

## 🎯 Recovery Checklist Template

**Use this after any recovery:**

```markdown
## Recovery Report: [Date]

**What broke:**
- [ ] Describe the problem

**Impact:**
- [ ] What couldn't work?
- [ ] How long was it broken?
- [ ] Data lost? (Yes/No)

**Root cause:**
- [ ] Why did it happen?

**Recovery steps:**
1. [ ] Step 1
2. [ ] Step 2
3. [ ] Step 3

**Time to recover:**
- Started: [time]
- Resolved: [time]
- Total: [duration]

**Prevention added:**
- [ ] New git hook
- [ ] Updated .gitignore
- [ ] New test
- [ ] Documentation updated

**Lessons learned:**
- [ ] What will I do differently?
```

---

**Remember: Every failure is a learning opportunity. Document it, fix it, prevent it, move on. 🚀**

---

**[⬅️ Back to Process Improvements](../PROCESS_IMPROVEMENTS_ACTION_PLAN.md)** | **[📖 Master Plan](../ENTERPRISE_TRANSFORMATION_MASTER.md)**
