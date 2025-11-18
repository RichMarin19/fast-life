# 📅 Workflow Routines

**Daily and weekly processes to stay on track**

---

## 📋 Overview

**Purpose:** Consistent routines prevent chaos, ensure quality, and maintain momentum.

**Why this matters:**
- Prevents forgetting critical tasks
- Builds good habits
- Catches issues early
- Maintains code quality
- Tracks progress accurately

**Time investment:**
- Daily routine: 15-30 minutes
- Weekly routine: 60-90 minutes
- **Saves:** 10+ hours per week in rework

---

## ☀️ Daily Routine (Every Work Day)

### Morning Startup (10 min)

**Purpose:** Set up for productive day

**Tasks:**
```bash
cd /Users/richmarin/fast-life

# 1. Pull latest changes (if working with team)
git pull origin main

# 2. Check CI status
# Visit GitHub Actions tab
# Verify all workflows green

# 3. Review today's goals
cat docs/ROADMAP_TIMELINE.md | grep "Week X, Day Y"

# 4. Start format-on-save
./scripts/format_on_save.sh &

# 5. Check for dependency updates (Monday only)
# File > Packages > Update to Latest Package Versions
```

**Output:** Ready to code with clear goals

---

### Before Each Coding Session (5 min)

**Purpose:** Start clean

**Tasks:**
1. ✅ Review Definition of Done for current task
2. ✅ Create feature branch (if new task)
   ```bash
   git checkout -b feature/sleep-tracking
   ```
3. ✅ Update todo list
   ```markdown
   # In your notes or docs/ROADMAP_TIMELINE.md
   - [ ] Implement SleepRepository protocol
   - [ ] Write 20+ unit tests
   - [ ] Integration test with HealthKit
   ```

---

### During Coding (Continuous)

**Purpose:** Maintain quality as you go

**Best practices:**
- ✅ Commit frequently (every 30-60 minutes)
  ```bash
  git add .
  git commit -m "feat: implement sleep repository read operations"
  ```
- ✅ Run tests after each file saved
  ```bash
  # In separate terminal
  fswatch -o **/*.swift | xargs -n1 -I{} xcodebuild test -scheme FastingTracker
  ```
- ✅ Add doc comments as you write code
  ```swift
  /// Retrieves all sleep entries within the specified date range
  /// - Parameters:
  ///   - from: Start date (inclusive)
  ///   - to: End date (inclusive)
  /// - Returns: Array of sleep entries sorted by bed time (descending)
  func getEntriesInRange(from: Date, to: Date) async throws -> [SleepEntry]
  ```

---

### End of Coding Session (10 min)

**Purpose:** Leave clean state for next session

**Tasks:**
```bash
# 1. Run full test suite
xcodebuild test -workspace FastingTracker.xcworkspace -scheme FastingTracker

# 2. Check for uncommitted changes
git status

# 3. Commit WIP if needed
git add .
git commit -m "wip: sleep repository 80% complete"

# 4. Push to remote (backup)
git push origin feature/sleep-tracking

# 5. Update progress notes
echo "$(date): Completed SleepRepository read operations. TODO: Implement write operations tomorrow." >> progress.md
```

---

### Evening Shutdown (15 min)

**Purpose:** Reflect and plan tomorrow

**Tasks:**

**1. Review today's progress (5 min)**
```bash
# What did I complete?
git log --since="1 day ago" --oneline

# Check Definition of Done
# Mark completed items
```

**2. Check metrics (5 min)**
```bash
# Test coverage
./scripts/coverage_report.sh

# Code quality
./scripts/fl-lint

# Lines of code changed
git diff --stat main
```

**3. Plan tomorrow (5 min)**
```markdown
# In notes or calendar

Tomorrow (Wednesday):
- [ ] Complete SleepRepository write operations (3h)
- [ ] Write remaining 15 unit tests (2h)
- [ ] Integration test with HealthKit (2h)
- [ ] Code review cleanup (1h)

Goal: Finish SleepRepository completely
```

**4. Celebrate wins 🎉**
```
✅ Implemented 5 repository methods
✅ Wrote 12 unit tests (all passing)
✅ Test coverage increased from 42% to 46%
```

---

## 🗓️ Weekly Routine (Every Friday)

### Week Review (30 min)

**Purpose:** Assess progress and adjust

**Tasks:**

**1. Measure against success metrics (10 min)**
```bash
# Test coverage
./scripts/coverage_report.sh
# Record: Phase 1 Week 5: 46% coverage (target: 40%+) ✅

# Tests count
find . -name "*Tests.swift" -exec grep -c "func test" {} + | awk '{s+=$1} END {print s}'
# Record: 127 tests (target: 100+) ✅

# SwiftLint violations
./scripts/fl-lint | grep "violation"
# Record: 3 violations (target: 0) ❌ TODO: Fix

# Build time
xcodebuild -workspace FastingTracker.xcworkspace -scheme FastingTracker clean build 2>&1 | grep "Build Succeeded"
# Record: 34.2s (target: <60s) ✅
```

**2. Review roadmap progress (10 min)**
```markdown
# Update docs/ROADMAP_TIMELINE.md

## Week 5: DataLayer Completion ✅ COMPLETE

✅ Task 5.1: Implement HydrationRepository (8h)
✅ Task 5.2: Implement WeightRepository (8h)
✅ Task 5.3: Implement SleepRepository (8h)
⏳ Task 5.4: Dependency Injection Container (4h/8h) - 50% complete

Status: 28/32 hours complete (87.5%)
```

**3. Identify blockers (10 min)**
```markdown
# In progress.md or issue tracker

## Blockers This Week
1. ⚠️ SwiftData migration failing on simulator
   - Impact: Can't test SleepRepository fully
   - Solution: Delete app and rebuild (see TROUBLESHOOTING.md)
   - Status: Resolved

2. ⚠️ HealthKit authorization not prompting
   - Impact: Can't test sleep data sync
   - Solution: Must test on device (simulator doesn't support HealthKit)
   - Status: Will test on device Monday

## Learnings
- SwiftData store resets when schema changes (expected)
- HealthKit requires real device for testing
- Snapshot tests caught UI regression in SleepQualityPicker
```

---

### Weekly Planning (30 min)

**Purpose:** Set up next week for success

**Tasks:**

**1. Review next week's tasks (10 min)**
```markdown
# From docs/ROADMAP_TIMELINE.md

## Week 6: Feature Packages (Part 1)

Monday (8h):
- [ ] Create FeatureFasting package structure
- [ ] Implement FastingTrackingViewModel
- [ ] Write 5 ViewModel tests

Tuesday (8h):
- [ ] Implement FastingTrackingView
- [ ] Implement FastingHistoryViewModel
- [ ] Write 5 more ViewModel tests

Wednesday (8h):
- [ ] Implement FastingHistoryView
- [ ] Create FastingProgressRing component
- [ ] Snapshot tests for views

Thursday (8h):
- [ ] Create FeatureHydration package
- [ ] Implement HydrationTrackingViewModel
- [ ] Write ViewModel tests

Friday (8h):
- [ ] Implement HydrationTrackingView
- [ ] Weekly review
- [ ] Prepare Week 7 tasks
```

**2. Prepare dependencies (10 min)**
```bash
# Install any new tools needed
# brew install jazzy  # If starting documentation week

# Update packages
cd /Users/richmarin/fast-life
xcodebuild -workspace FastingTracker.xcworkspace -scheme FastingTracker -resolvePackageDependencies

# Create branches for next week's features
git checkout -b feature/fasting-package
git checkout -b feature/hydration-package
git checkout main
```

**3. Update documentation (10 min)**
```bash
# Update PROGRESS.md or similar
cat >> PROGRESS.md << EOF

---

## Week 5 Summary ($(date +%Y-%m-%d))

**Completed:**
- ✅ HydrationRepository (all CRUD operations)
- ✅ WeightRepository (all CRUD operations)
- ✅ SleepRepository (all CRUD operations)
- ✅ 45 new unit tests (all passing)

**Metrics:**
- Test coverage: 42% → 46%
- Total tests: 82 → 127
- Lines of code: 4,230 → 5,890 (+1,660)

**Next Week Goals:**
- Create FeatureFasting package
- Create FeatureHydration package
- Reach 50%+ test coverage
- Complete Phase 1 Week 6 tasks

EOF
```

---

### Weekly Maintenance (30 min)

**Purpose:** Keep codebase healthy

**Tasks:**

**1. Dependency updates (10 min)**
```bash
# Check for outdated dependencies
cd /Users/richmarin/fast-life

# Update Swift packages
# Xcode > File > Packages > Update to Latest Package Versions

# Update CocoaPods (if used)
# pod update

# Check for security vulnerabilities
# (No official tool for Swift, but check GitHub security alerts)

# Test after updates
xcodebuild test -workspace FastingTracker.xcworkspace -scheme FastingTracker
```

**2. Code quality cleanup (10 min)**
```bash
# Fix SwiftLint violations
./scripts/fl-lint --fix

# Remove unused code
# (Manual review)

# Update deprecated APIs
# (Check compiler warnings)

# Commit cleanup
git add .
git commit -m "chore: weekly code quality cleanup"
```

**3. Backup and organization (10 min)**
```bash
# Push all branches
git push --all origin

# Clean old branches (merged)
git branch --merged | grep -v "\*\|main\|develop" | xargs -n 1 git branch -d

# Archive old notes
mkdir -p archive/$(date +%Y-%m)
mv progress-old.md archive/$(date +%Y-%m)/

# Update README if needed
# (Add new features, update stats)
```

---

## 🚀 Phase Transition Routines

### Starting New Phase

**Before Phase 0:**
```bash
# 1. Read phase guide completely
open docs/PHASE_0_FOUNDATION.md

# 2. Set up automation
./scripts/setup_all.sh

# 3. Create tracking document
cp docs/PHASE_0_FOUNDATION.md docs/PHASE_0_PROGRESS.md

# 4. Block calendar (3 weeks)
# Add Phase 0 tasks to calendar

# 5. Announce start
git commit --allow-empty -m "Start Phase 0: Foundation 🏗️"
```

**Before Phase 1:**
```bash
# 1. Verify Phase 0 complete
# Check all items in DEFINITION_OF_DONE.md for Phase 0

# 2. Celebrate Phase 0 completion 🎉
git tag phase-0-complete
git push origin phase-0-complete

# 3. Review Phase 1 guide
open docs/PHASE_1_ARCHITECTURE_COMPLETE.md

# 4. Set up packages directory
mkdir -p Packages/{Core,DesignSystem,DataLayer,FeatureFasting,FeatureHydration,FeatureWeight,FeatureSleep}

# 5. Update roadmap tracking
# Mark Phase 0 complete in ROADMAP_TIMELINE.md
```

**Before Phase 2:**
```bash
# 1. Verify Phase 1 complete (all packages working)
xcodebuild test -workspace FastingTracker.xcworkspace -scheme "All Tests"

# 2. Celebrate Phase 1 🎉
git tag phase-1-complete
git push origin phase-1-complete

# 3. Review Phase 2 guide
open docs/PHASE_2_SCALE_POLISH_COMPLETE.md

# 4. Install Phase 2 tools
brew install jazzy  # Documentation
gem install snapshot  # Snapshot testing

# 5. Set up beta testing
# Create TestFlight beta group in App Store Connect
```

---

### Completing Phase

**Phase 0 Completion:**
```bash
# 1. Run all validation commands from DEFINITION_OF_DONE.md

# 2. Generate completion report
cat > PHASE_0_COMPLETE.md << EOF
# Phase 0: Foundation - COMPLETE ✅

**Completion Date:** $(date +%Y-%m-%d)
**Duration:** 3 weeks (21 days)
**Hours:** 38 hours (planned: 30-40h)

## Completed Tasks
- ✅ Privacy manifest
- ✅ CI/CD pipeline (GitHub Actions)
- ✅ Keychain security (UserDefaults → Keychain)
- ✅ Crash reporting (Firebase)
- ✅ Structured logging (os_log)
- ✅ Basic tests (24 tests)

## Metrics
- Test coverage: 0% → 18%
- CI/CD: 0 → 3 workflows
- Code quality: Manual → Automated (SwiftLint)

## Next: Phase 1 (Weeks 4-8)
EOF

# 3. Commit and tag
git add PHASE_0_COMPLETE.md
git commit -m "Complete Phase 0: Foundation 🎉"
git tag phase-0-complete
git push origin main --tags

# 4. Take 2-day break
# Seriously. Rest before Phase 1.
```

---

## 🎯 Habit Building

### First 2 Weeks

**Focus:** Establish daily routine

**Goals:**
- ✅ Daily morning startup (10 min)
- ✅ Commit at least 3 times per day
- ✅ Run tests before every commit
- ✅ Daily evening review (15 min)

**Tips:**
- Set phone reminders for routines
- Use Pomodoro technique (25min focus, 5min break)
- Track habits in calendar (X = completed)

---

### Weeks 3-4

**Focus:** Add weekly routines

**Goals:**
- ✅ All daily routines automatic
- ✅ Weekly review every Friday
- ✅ Weekly planning for next week
- ✅ Update progress documentation

**Tips:**
- Block Friday afternoon for weekly review
- Celebrate weekly wins (treat yourself)
- Share progress (blog, Twitter, team)

---

### Weeks 5+

**Focus:** Optimize and refine

**Goals:**
- ✅ Routines feel natural
- ✅ Identify time-wasters, eliminate them
- ✅ Add custom routines for your workflow
- ✅ Help others with your process

**Tips:**
- Review this document monthly
- Update routines based on what works
- Automate repetitive tasks (scripts)

---

## 🛠️ Tools & Automation

### Recommended Tools

**Time tracking:**
```bash
# Toggl Track (free tier)
# Track time per task
# Review weekly in routines

# Or simple script
echo "$(date): Started SleepRepository implementation" >> time-log.txt
```

**Task management:**
```bash
# GitHub Projects (built-in)
# Create board with columns: To Do, In Progress, Done

# Or use Notion, Trello, etc.
```

**Code review:**
```bash
# Use GitHub Pull Requests
# Even for solo projects (good practice)

git checkout -b feature/sleep-tracking
# ... make changes ...
git push origin feature/sleep-tracking

# Create PR on GitHub
# Review your own code
# Merge when ready
```

---

## 📊 Progress Tracking Template

**Create:** `PROGRESS.md` in project root

**Template:**
```markdown
# Fast LIFe Progress Tracker

## Current Phase: 1
## Current Week: 5/8
## Current Score: 6.2/10 (Target: 7.5/10 by end of Phase 1)

---

## This Week (Week 5)

**Goal:** Complete DataLayer repositories

**Daily Progress:**

### Monday (8h)
- ✅ Implemented HydrationRepository
- ✅ Wrote 20 unit tests
- ✅ All tests passing
- 📊 Coverage: 42% → 44%

### Tuesday (8h)
- ✅ Implemented WeightRepository
- ✅ Wrote 18 unit tests
- ✅ Integration test with SwiftData
- 📊 Coverage: 44% → 45%

### Wednesday (6h)
- ⏳ Started SleepRepository (50% complete)
- ✅ Protocol defined
- ✅ Read operations implemented
- ⏳ Write operations TODO

### Thursday (planned)
- [ ] Complete SleepRepository
- [ ] Write 25 unit tests
- [ ] Integration tests

### Friday (planned)
- [ ] Dependency Injection Container
- [ ] Weekly review
- [ ] Plan Week 6

---

## Metrics Tracking

| Metric | Week 4 | Week 5 | Target | Status |
|--------|--------|--------|--------|--------|
| Test Coverage | 38% | 45% | 40%+ | ✅ On track |
| Total Tests | 62 | 120 | 100+ | ✅ Exceeding |
| SwiftLint Violations | 12 | 5 | 0 | ⚠️ Needs work |
| Build Time | 28s | 34s | <60s | ✅ Good |

---

## Blockers & Issues

### Active
- None ✅

### Resolved
1. SwiftData migration failing → Deleted app and rebuilt ✅
2. HealthKit not working → Tested on device (simulator doesn't support) ✅

---

## Learnings

- SwiftData requires migration plan for schema changes
- Snapshot tests are amazing for catching UI regressions
- async/await makes code so much cleaner
- Writing tests first (TDD) actually saves time

---

## Next Week Preview

**Week 6: Feature Packages**
- Create FeatureFasting package
- Create FeatureHydration package
- Reach 50%+ coverage
- 40+ hours planned
```

---

## 🎯 Success Indicators

**You're doing it right when:**
- ✅ Daily routines take <30 minutes total
- ✅ Never wondering "what should I work on?"
- ✅ Always know your current progress
- ✅ Tests catch bugs before you see them
- ✅ Git history tells a clear story
- ✅ Documentation stays up to date
- ✅ Weekly goals consistently met

**Warning signs:**
- ❌ Skipping routines regularly
- ❌ Forgetting to commit code
- ❌ Tests haven't run in days
- ❌ Don't know current coverage
- ❌ Documentation outdated
- ❌ Missing weekly goals
- ❌ Blocked with no plan to unblock

**Fix by:**
1. Review this document
2. Identify which routine you're skipping
3. Understand why (too long? not valuable?)
4. Adjust routine or recommit to it
5. Use calendar reminders
6. Pair with accountability partner

---

## 🚀 Getting Started

**This Week:**
1. ✅ Copy daily routine to sticky note on monitor
2. ✅ Set calendar event for Friday weekly review
3. ✅ Create PROGRESS.md file
4. ✅ Do morning routine before starting work
5. ✅ Do evening routine before stopping work

**By End of Week:**
- ✅ Completed 5 daily routines
- ✅ Completed 1 weekly review
- ✅ Progress documented
- ✅ Metrics tracked

**Then:**
- Routines become automatic
- Quality improves
- Velocity increases
- Stress decreases
- **Fast LIFe becomes LEGENDARY** 🏆

---

**[⬅️ Back to Process Improvements](../PROCESS_IMPROVEMENTS_ACTION_PLAN.md)** | **[📖 Master Plan](../ENTERPRISE_TRANSFORMATION_MASTER.md)**
