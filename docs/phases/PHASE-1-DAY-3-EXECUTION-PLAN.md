# Phase 1 Day 3: Fasting Tracker Refactor - Execution Plan

**Date:** October 17, 2025
**Phase:** Phase 1 - Code Refactoring (Day 3-7)
**Focus:** ContentView.swift (Fasting Tracker)
**Goal:** 652 LOC → 250 LOC (Apply TrackerScreenShell + Extract Components)

---

## 🎯 Mission Statement

**REVAMP ContentView (Fasting Tracker) to match Weight Tracker North Star pattern:**
- Apply `TrackerScreenShell` for consistent UI across all trackers
- Extract 4-5 composable components (Timer, Stats, History, Controls, Goal)
- Reduce from 652 LOC to ≤250 LOC
- Follow Weight Tracker's proven UX pattern (257 LOC reference)

**North Star:** WeightTrackingView.swift (257 LOC)
- ✅ Uses TrackerScreenShell wrapper
- ✅ Clean component extraction (CurrentWeightCard, WeightChartView, WeightStatsView, WeightHistoryListView)
- ✅ Empty state pattern
- ✅ Settings gear icon
- ✅ HealthKit nudge integration

---

## 📚 Pre-Flight Review Complete

### ✅ HANDOFF Documentation Reviewed

**Critical Pitfalls to AVOID (from HANDOFF.md):**
1. ❌ **Xcode Project Management** → Add new files to project IMMEDIATELY
2. ❌ **State Management Errors** → Use correct property wrappers (@StateObject vs @ObservedObject)
3. ❌ **Component Extraction Sequencing** → Preserve state variables in correct locations
4. ❌ **Generic Type Inference** → Use direct initializers
5. ❌ **Duplicate Type Definitions** → Centralize shared types
6. ❌ **SwiftUI Compilation Timeout** → Keep body under 500 lines
7. ❌ **Duplicate UI Rendering** → Remove content from main body after extraction

**Patterns to REPEAT (from Phase 3 success):**
1. ✅ Large Components First → Extract biggest impact first
2. ✅ Shared Components Second → Create reusable architecture
3. ✅ Apple MVVM Patterns → Follow official guidelines
4. ✅ Preserve Functionality → NEVER change working features
5. ✅ @StateObject for New Instances
6. ✅ @ObservedObject for Shared Instances
7. ✅ Test After Each Extraction

**Critical Rules (NEVER VIOLATE):**
- ❌ NEVER touch code that works (unless extracting)
- ✅ ALWAYS test after each component extraction
- ✅ ALWAYS maintain existing functionality
- ✅ ALWAYS verify HealthKit sync operational after changes

---

## 🏗️ Industry Leader Strategy

### Decision Lens Applied:

**1. Industry Standards (Apple/Meta/Google)**
- **Apple SwiftUI Best Practices:** Small, composable views (50-150 LOC each)
- **Meta React Philosophy:** Component-based architecture with single responsibility
- **Google Material Design:** Modular UI components with clear boundaries

**2. Official Documentation**
- **Apple SwiftUI Guidelines:** Views should be small and focused
- **Apple MVVM Pattern:** Separate presentation from business logic
- **SwiftUI Performance:** Keep view body simple to avoid compilation timeouts

**3. Project Ethos**
- "Measure twice, cut once" → Map everything BEFORE cutting
- "Never touch code that works" → Only extract, don't modify
- "Test after each extraction" → Verify functionality preserved

---

## 📊 Current State Analysis

### ContentView.swift - Current Metrics
- **Total LOC:** 652 lines
- **Target LOC:** ≤250 lines
- **Reduction Needed:** -402 lines (-62%)
- **Risk Level:** 🔴 HIGH (main app view, complex timer logic)

### Component Structure (Lines of Interest)
Based on HANDOFF-PHASE-C.md extraction opportunities:
1. **HealthKit Nudge Section** → Already extracted pattern (lines 55-70)
2. **Title Section** → Header + timer state badge (lines ~80-110)
3. **Timer Section** → Main timer display + progress ring (lines ~191-276)
4. **Goal Section** → Goal settings + edit button (lines ~300-338)
5. **Stats Section** → Streak + average stats (lines ~285-298)
6. **History Section** → Past fasts list (lines ~428-467)
7. **Controls Section** → Start/Stop/Resume buttons (lines ~341-426)

###State Properties (Must Preserve):
```swift
@EnvironmentObject var fastingManager: FastingManager
@StateObject private var nudgeManager = HealthKitNudgeManager.shared
@State private var showingGoalSettings: Bool
@State private var showingStopConfirmation: Bool
@State private var showingDeleteConfirmation: Bool
@State private var showingEditTimes: Bool
@State private var showingEditStartTime: Bool
@State private var selectedStage: FastingStage?
@State private var showHealthKitNudge: Bool
@State private var showingSyncOptions: Bool
@State private var selectedDate: Date?
```

---

## 🎯 North Star Application Plan

### STEP 0: Apply TrackerScreenShell Wrapper (PRIORITY 1)
**Purpose:** Wrap ContentView in TrackerScreenShell to match Weight Tracker pattern
**What This Gives Us:**
- ✅ Consistent title styling ("Fast", "in", "g Tracker")
- ✅ Settings gear icon (top right)
- ✅ HealthKit nudge integration (top banner)
- ✅ Scrollable content area
- ✅ Empty state support

**Pattern from WeightTrackingView:**
```swift
TrackerScreenShell(
    title: ("Fasting Tr", "ac", "ker"),  // or ("Fast", "in", "g Tracker")
    hasData: !fastingManager.completedFasts.isEmpty,
    nudge: healthKitNudgeView,
    settingsAction: { showingSettings = true }
) {
    // Main content goes here
}
```

---

### Component Extraction Plan (4-5 Components)

Matching Weight Tracker's component structure:

### Component 1: Current Fast Card (like CurrentWeightCard)
**Purpose:** Timer display + progress ring + current stage + quick actions
**Estimated LOC:** ~100-120 lines
**Properties Needed:**
- `@ObservedObject var fastingManager: FastingManager`
- `@Binding var showingEditTimes: Bool`
- `@Binding var showingStopConfirmation: Bool`
- `@Binding var selectedStage: FastingStage?`
**File:** `UI/Components/Fasting/CurrentFastCard.swift`

### Component 2: Fasting Chart View (like WeightChartView)
**Purpose:** Visual history of fasts over time
**Estimated LOC:** ~80-100 lines
**Properties Needed:**
- `@ObservedObject var fastingManager: FastingManager`
- `@Binding var selectedTimeRange: TimeRange`
**File:** `UI/Components/Fasting/FastingChartView.swift`

### Component 3: Fasting Stats View (like WeightStatsView)
**Purpose:** Streak + average + total stats
**Estimated LOC:** ~40-60 lines
**Properties Needed:**
- `@ObservedObject var fastingManager: FastingManager`
**File:** `UI/Components/Fasting/FastingStatsView.swift`

### Component 4: Fasting History List (like WeightHistoryListView)
**Purpose:** Recent fasts list
**Estimated LOC:** ~50-70 lines
**Properties Needed:**
- `@ObservedObject var fastingManager: FastingManager`
**File:** `UI/Components/Fasting/FastingHistoryListView.swift`

### Component 5: Empty Fast State (like EmptyWeightStateView)
**Purpose:** First-time user experience
**Estimated LOC:** ~40-60 lines
**Properties Needed:**
- `@Binding var showingGoalSettings: Bool`
- `fastingManager: FastingManager`
**File:** `UI/Components/Fasting/EmptyFastStateView.swift`

**Total Extracted:** ~310-410 LOC
**TrackerScreenShell Wrapper:** ~40-50 LOC
**Remaining in ContentView:** ~200-290 LOC
**Target Met:** ✅ ≤250 LOC achievable with North Star pattern

---

## 📋 Step-by-Step Execution Plan

### STEP 0: Apply TrackerScreenShell Wrapper (20-30 min) 🌟 NORTH STAR

**Goal:** Wrap ContentView in TrackerScreenShell to match Weight Tracker UI pattern

**0.1 Study Weight Tracker Pattern**
- Review WeightTrackingView.swift lines 58-99
- Note: TrackerScreenShell wrapper, hasData logic, nudge integration, settings action

**0.2 Modify ContentView Structure**
- Replace current NavigationView + ScrollView with TrackerScreenShell
- Move HealthKit nudge into `healthKitNudgeView` computed property (like Weight Tracker)
- Add settings sheet binding
- Structure: TrackerScreenShell → Empty State OR Component List

**0.3 Update Title & Toolbar**
- Change title to: `("Fasting Tr", "ac", "ker")` or `("Fast", "in", "g Tracker")`
- Remove custom toolbar (TrackerScreenShell provides gear icon)
- Move settings action to TrackerScreenShell parameter

**0.4 Test TrackerScreenShell Application**
- Build and run
- Verify title displays with Fast LIFe colors
- Verify gear icon appears (top right)
- Verify HealthKit nudge shows/hides correctly
- Verify content scrolls properly

**Exit Criteria:**
- ✅ ContentView wrapped in TrackerScreenShell
- ✅ Title displays with tri-color styling
- ✅ Settings gear icon functional
- ✅ HealthKit nudge integrated
- ✅ Build succeeds, UI matches Weight Tracker pattern

**LOC Impact:** -20 to -30 LOC (TrackerScreenShell replaces custom navigation/scroll code)

---

### STEP 1: Create Component Directory Structure (5 min)
```bash
mkdir -p FastingTracker/UI/Components/Fasting
```

**Exit Criteria:**
- ✅ Directory exists
- ✅ Path confirmed

---

### STEP 2: Extract CurrentFastCard (30-45 min)

**2.1 Create File**
- Create `UI/Components/Fasting/FastingTimerView.swift`
- Add to Xcode project immediately (ALL sections)

**2.2 Extract Timer Code**
- Copy timer section from ContentView (lines ~191-276)
- Add proper imports and struct declaration
- Define required properties (@ObservedObject, @Binding)
- Copy computed properties if needed

**2.3 Update ContentView**
- Replace timer section with: `FastingTimerView(fastingManager: fastingManager, selectedStage: $selectedStage)`
- Remove extracted code
- Keep state declarations

**2.4 Test**
- Build project (Cmd+B)
- Run app in simulator
- Verify timer displays correctly
- Verify timer updates in real-time
- Verify stage selection works

**Exit Criteria:**
- ✅ Build succeeds (0 errors, 0 warnings)
- ✅ Timer displays and updates
- ✅ Stage selection functional
- ✅ ContentView LOC reduced

---

### STEP 3: Extract FastingControlsView (30-45 min)

**3.1 Create File**
- Create `UI/Components/Fasting/FastingControlsView.swift`
- Add to Xcode project

**3.2 Extract Controls Code**
- Copy controls section from ContentView (lines ~341-426)
- Add sheet modifiers for EditTimes, StopConfirmation, etc.
- Define required bindings

**3.3 Update ContentView**
- Replace controls with component
- Pass all required bindings

**3.4 Test**
- Build and run
- Verify Start/Stop/Resume buttons work
- Verify edit dialogs appear
- Verify confirmations work

**Exit Criteria:**
- ✅ All buttons functional
- ✅ Dialogs appear correctly
- ✅ Timer starts/stops as expected

---

### STEP 4: Extract FastingGoalView (20-30 min)

**4.1 Create File**
- Create `UI/Components/Fasting/FastingGoalView.swift`
- Add to Xcode project

**4.2 Extract Goal Code**
- Copy goal section (lines ~300-338)
- Include goal settings sheet

**4.3 Update ContentView**
- Replace with component
- Pass fastingManager and showingGoalSettings binding

**4.4 Test**
- Verify goal displays
- Verify edit button opens settings
- Verify goal changes save

**Exit Criteria:**
- ✅ Goal displays correctly
- ✅ Settings dialog works
- ✅ Changes persist

---

### STEP 5: Extract FastingStatsView (20-30 min)

**5.1 Create File**
- Create `UI/Components/Fasting/FastingStatsView.swift`
- Add to Xcode project

**5.2 Extract Stats Code**
- Copy stats section (lines ~285-298)
- Include HealthKit sync button

**5.3 Update ContentView**
- Replace with component

**5.4 Test**
- Verify streak displays
- Verify average displays
- Verify sync button works

**Exit Criteria:**
- ✅ Stats display correctly
- ✅ HealthKit sync functional

---

### STEP 6: Extract FastingHistoryView (20-30 min)

**6.1 Create File**
- Create `UI/Components/Fasting/FastingHistoryView.swift`
- Add to Xcode project

**6.2 Extract History Code**
- Copy history section (lines ~428-467)

**6.3 Update ContentView**
- Replace with component

**6.4 Test**
- Verify history list displays
- Verify "View All" navigation works
- Verify past fasts show correctly

**Exit Criteria:**
- ✅ History displays
- ✅ Navigation works
- ✅ Data accurate

---

### STEP 7: Final Verification & LOC Check (15-20 min)

**7.1 Run LOC Gate**
```bash
bash scripts/loc_gate.sh | grep ContentView
```

**7.2 Comprehensive Testing**
- Start a new fast
- Stop a fast
- Edit fast times
- Change goal
- View history
- Check HealthKit sync

**7.3 Build Verification**
```bash
xcodebuild clean build -project FastingTracker.xcodeproj -scheme FastingTracker
```

**Exit Criteria:**
- ✅ ContentView ≤250 LOC
- ✅ All 5 components created
- ✅ Build succeeds
- ✅ All functionality preserved
- ✅ No regressions

---

## 🧪 Testing Checklist (Critical)

### Timer Functionality
- [ ] Timer displays current duration
- [ ] Timer updates every second
- [ ] Progress ring animates smoothly
- [ ] Stage icons appear correctly
- [ ] Stage selection opens detail view

### Control Functionality
- [ ] "Start Fast" button starts timer
- [ ] "Stop Fast" shows confirmation dialog
- [ ] "Resume" button continues timer
- [ ] "Edit Times" opens edit dialog
- [ ] "Edit Start Time" opens time picker

### Goal Functionality
- [ ] Goal displays current target
- [ ] Edit button opens settings
- [ ] Goal changes save and persist
- [ ] Goal affects timer display

### Stats Functionality
- [ ] Streak count accurate
- [ ] Average duration calculates correctly
- [ ] HealthKit sync button works
- [ ] Stats update after completing fast

### History Functionality
- [ ] Past fasts display in list
- [ ] "View All" navigates to history
- [ ] Selecting fast shows details
- [ ] History data persists

### HealthKit Integration
- [ ] Sync toggle works
- [ ] Data syncs to HealthKit
- [ ] Observer detects external changes
- [ ] No duplicates created

---

## 📊 Success Criteria (Definition of Done)

### LOC Reduction
- [x] ContentView ≤250 LOC (current: 652)
- [ ] FastingTimerView created (~100-120 LOC)
- [ ] FastingControlsView created (~90-110 LOC)
- [ ] FastingGoalView created (~50-70 LOC)
- [ ] FastingStatsView created (~40-60 LOC)
- [ ] FastingHistoryView created (~50-70 LOC)

### Code Quality
- [ ] Build succeeds (0 errors, 0 warnings)
- [ ] SwiftLint passes (no new violations)
- [ ] All components follow MVVM pattern
- [ ] State management correct (@StateObject/@ObservedObject/@Binding)
- [ ] No code duplication

### Functionality
- [ ] All timer functions work
- [ ] All controls work
- [ ] Goal editing works
- [ ] Stats display correctly
- [ ] History accessible
- [ ] HealthKit sync operational

### Testing
- [ ] Manual testing checklist complete
- [ ] No regressions found
- [ ] Performance acceptable (60fps timer updates)
- [ ] Memory usage stable

### Documentation
- [ ] Extraction logged in this document
- [ ] Any issues documented
- [ ] Lessons learned captured

---

## 🚨 Emergency Rollback Plan

If extraction causes critical issues:

**Immediate Rollback:**
```bash
git reset --hard HEAD
```

**Checkpoint Rollback:**
```bash
git reset --hard 544d940  # Phase 0 verification checkpoint
```

**Recovery Steps:**
1. Document what went wrong
2. Review HANDOFF-REFERENCE.md error tracking
3. Adjust approach based on lesson learned
4. Try again with modified strategy

---

## 📝 Notes & Observations

### Before Starting:
- Current ContentView: 652 LOC
- Reference (WeightTrackingView): 257 LOC
- All HANDOFF docs reviewed ✅
- Pre-flight checklist complete ✅

### During Extraction:
(Will document as we go)

### After Completion:
(Will document results)

---

## 🎯 Next Steps After Day 3

**Day 4-7 Goals:**
- Refactor HydrationTrackingView (584 → 300 LOC)
- Refactor SleepTrackingView (304 → 300 LOC)
- All trackers ≤300 LOC
- **Checkpoint 4** at EOD Day 7

---

**Execution Start:** Ready to begin
**Estimated Duration:** 2.5-3.5 hours
**Target Completion:** End of Day 3
**Checkpoint:** Checkpoint 2 (Day 3 EOD)
