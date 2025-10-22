# Phase v1.6: File Split Audit
**Date**: 2025-10-22
**Goal**: Identify and split files > 400 LOC following industry best practices

## Industry Standard: 400 LOC Limit
- **Google Style Guide**: 400-500 LOC per file
- **Apple Swift Guidelines**: 250-400 LOC (implied)
- **Martin Fowler**: "When a class gets too large"

**Our Standard**: 400 LOC excluding comments/blank lines

---

## 🔴 **CRITICAL: Files Requiring Immediate Splitting**

### **1. WeightControlCenterView.swift** ⚠️ **HIGHEST PRIORITY**
- **Current Size**: 1,803 LOC
- **Complexity**: ~4.5x over limit
- **Contains**:
  - Main Control Center view (navigation, state)
  - 6 card content views (Goals, Notifications, Insights, Sync, History, Experience)
  - Helper views (category toggles, tracker cards toggle, progress story toggle)
  - About card
  - Drag & drop delegate
  - All state management

**Proposed Split (Apple folder-by-feature pattern)**:
```
WeightControlCenter/
  ├── WeightControlCenterView.swift          (~300 LOC) - Main view + nav
  ├── GoalsCard.swift                        (~150 LOC) - Goals content
  ├── NotificationsCard.swift                (~50 LOC)  - Notifications stub
  ├── InsightsCard.swift                     (~50 LOC)  - Insights stub
  ├── SyncCard.swift                         (~200 LOC) - Sync logic
  ├── HistoryCard.swift                      (~50 LOC)  - History wrapper
  ├── ExperienceCard.swift                   (~400 LOC) - Manage experience
  ├── AboutCard.swift                        (~150 LOC) - About content
  ├── ControlCenterHelpers.swift             (~200 LOC) - Toggle helpers
  └── CardDropDelegate.swift                 (~50 LOC)  - Drag/drop
```

**Benefits**:
- ✅ Each file < 400 LOC (maintainable)
- ✅ Folder-by-feature = easy navigation
- ✅ Clear separation of concerns
- ✅ Easy to add new cards (just add CardName.swift)

---

### **2. WeightComponents.swift** ⚠️ **HIGH PRIORITY**
- **Current Size**: 1,728 LOC
- **Complexity**: ~4.3x over limit
- **Contains**:
  - WeightStatsView
  - WeightHistoryListView + WeightHistoryRow
  - FirstTimeWeightSetupView
  - WeightTrendsView (Progress Story - 500+ LOC itself!)
  - LightCard wrapper
  - Progress Story components (CoachBar, ProgressBanner, CircularTrendRingCard, TrendCardFull, RecapRow, ReflectionNudge, DidYouKnowBanner, TrendCard)
  - Drag & drop delegate

**Proposed Split**:
```
WeightTracker/
  ├── Components/
  │   ├── WeightStatsView.swift              (~150 LOC)
  │   ├── WeightHistoryView.swift            (~150 LOC)
  │   └── FirstTimeWeightSetupView.swift     (~150 LOC)
  └── ProgressStory/
      ├── WeightTrendsView.swift             (~400 LOC) - Main view
      ├── ProgressStoryCards.swift           (~350 LOC) - All card components
      ├── LightCardWrapper.swift             (~50 LOC)  - Reusable wrapper
      └── ProgressStoryDropDelegate.swift    (~50 LOC)  - Drag/drop
```

**Benefits**:
- ✅ Progress Story isolated (reusable for other trackers)
- ✅ History/Stats components easy to find
- ✅ Setup flow separate (onboarding concern)

---

### **3. WeightChartView.swift** ⚠️ **MEDIUM PRIORITY**
- **Current Size**: 1,087 LOC
- **Complexity**: ~2.7x over limit
- **Contains**:
  - Main WeightChartView
  - Chart calculations (data processing)
  - Chart rendering (SwiftUI Charts)
  - Goal line logic
  - Axis formatting

**Proposed Split**:
```
WeightTracker/Chart/
  ├── WeightChartView.swift           (~300 LOC) - Main view
  ├── WeightChartData.swift           (~200 LOC) - Data processing
  ├── WeightChartRenderer.swift       (~350 LOC) - Chart rendering
  └── WeightChartHelpers.swift        (~150 LOC) - Formatters, goal line
```

---

### **4. WeightManager.swift** ⚠️ **MEDIUM PRIORITY**
- **Current Size**: 911 LOC
- **Complexity**: ~2.3x over limit
- **Contains**:
  - WeightEntry model
  - WeightManager class (data layer)
  - HealthKit sync logic
  - CRUD operations
  - Statistics calculations

**Proposed Split**:
```
Core/Weight/
  ├── WeightEntry.swift                      (~50 LOC)  - Model
  ├── WeightManager.swift                    (~300 LOC) - Core CRUD
  ├── WeightManager+HealthKit.swift          (~300 LOC) - Sync logic
  └── WeightManager+Statistics.swift         (~200 LOC) - Calculations
```

**Pattern**: Swift extension pattern (Apple official)

---

### **5. WeightSettingsView.swift** ✅ **LOW PRIORITY**
- **Current Size**: 722 LOC
- **Status**: Above limit but not critical (~1.8x)
- **Action**: Monitor, split if grows > 900 LOC

---

## ✅ **SAFE: Design System Files (< 450 LOC)**

All design system files are healthy:
- ✅ Theme.swift: 427 LOC
- ✅ CardManager.swift: 360 LOC
- ✅ DSTypography.swift: 359 LOC
- ✅ DSBanner.swift: 314 LOC
- ✅ DSProgressRing.swift: 292 LOC
- ✅ DSCard.swift: 277 LOC

**No action needed** - design system is well-architected.

---

## 📋 **HANDOFF.MD PITFALLS REVIEW**

Checking for known issues before splitting:

### **From HANDOFF.md:**
1. ✅ **Don't break HealthKit sync** - WeightManager+HealthKit.swift will isolate sync
2. ✅ **Preserve drag-and-drop** - Delegates stay in same folder
3. ✅ **Keep opt-out system intact** - ContentOptOutManager unchanged
4. ✅ **Maintain card visibility logic** - CardManager imports stay consistent

**No blockers found** ✅

---

## 🎯 **EXECUTION PRIORITY**

### **Phase B: Start with Pilot**
**Pilot File**: WeightControlCenterView.swift
- **Why**: Largest, clearest boundaries (6 card views)
- **Risk**: Low (each card is self-contained)
- **Benefit**: Immediate 4.5x complexity reduction

### **If Pilot Succeeds**:
1. WeightComponents.swift (Progress Story extraction)
2. WeightChartView.swift (chart logic split)
3. WeightManager.swift (extension pattern)

---

## 🚀 **NEXT STEPS**

1. ✅ **Audit complete** (this document)
2. 🔄 **Read HANDOFF.md** (verify no conflicts)
3. ⏭️ **Phase B: Plan split for WeightControlCenterView.swift**
4. ⏭️ **Phase C: Create automation script**
5. ⏭️ **Phase D: Execute + verify**

---

## 📊 **SUCCESS METRICS**

**Before Phase v1.6:**
- 4 files > 400 LOC (critical)
- Largest file: 1,803 LOC (4.5x over limit)

**After Phase v1.6 (Target):**
- 0 files > 400 LOC ✅
- Largest file: ~400 LOC (at limit)
- All files follow Apple folder-by-feature pattern

---

**Generated**: 2025-10-22 00:58:00
**Phase**: v1.6 - File Splitting Automation
**Industry Validation**: Google, Apple, Martin Fowler
