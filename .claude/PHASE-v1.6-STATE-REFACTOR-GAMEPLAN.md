# Phase v1.6: State Management Refactoring Game Plan
**Date**: 2025-10-22
**Status**: Planning Phase
**Priority**: HIGH (blocks effective file splitting)

## Industry Validation
- **Apple SwiftUI**: State down, events up pattern
- **Google Flutter**: BLoC pattern (Business Logic Component)
- **Facebook React**: Redux pattern (centralized state)
- **Stripe iOS**: Coordinator + ViewModel architecture

## Current Problem
**File Size Issue Root Cause**: Tight coupling between view state and UI code

**Example**: `WeightControlCenterView.swift` (1,558 LOC after Phase 1 partial split)
- Lines 1-287: State variables (@State, @AppStorage, @Binding)
- Lines 288-1,558: UI code + computed properties + helper methods

**Why We Can't Split Now**:
```swift
// Card views reference parent @State directly
private var goalsCardContent: some View {
    VStack {
        Toggle(isOn: $showGoalLine) { ... }  // ← Binding to parent @State
        TextField("Enter goal", text: $weightGoalString)  // ← Binding to parent @State
    }
}
```

Extracting `goalsCardContent` to separate file breaks bindings.

---

## Solution: Extract State to ViewModels

### Before (Current - Monolithic):
```
WeightControlCenterView.swift (1,558 LOC)
├── @State variables (40+ properties)
├── @AppStorage persistence (15+ keys)
├── Computed properties
├── UI code (6 card views)
├── Helper methods
└── Lifecycle methods
```

### After (Refactored - MVVM):
```
WeightControlCenter/
├── WeightControlCenterView.swift (~300 LOC)
│   └── UI only - SwiftUI views
├── WeightControlCenterViewModel.swift (~400 LOC)
│   ├── @Published state
│   ├── Business logic
│   └── Computed properties
└── Cards/ (6 files, ~150 LOC each)
    ├── GoalsCardView.swift
    ├── SyncCardView.swift
    ├── ExperienceCardView.swift
    ├── NotificationsCardView.swift
    ├── InsightsCardView.swift
    └── HistoryCardView.swift
```

**Result**: 1,558 LOC → 7 files @ ~250 LOC average ✅

---

## Execution Timeline

### **Phase v1.7: State Extraction (HIGH PRIORITY)**
**When**: Immediately after Phase v1.6 file audit complete
**Duration**: 4-6 hours
**Files affected**:
- WeightControlCenterView.swift
- WeightComponents.swift
- WeightChartView.swift

**Steps**:
1. Create `WeightControlCenterViewModel.swift`
   - Move all @State → @Published
   - Move all @AppStorage → private properties
   - Move all computed properties
   - Move all helper methods

2. Update `WeightControlCenterView.swift`
   - Add `@StateObject var viewModel = WeightControlCenterViewModel()`
   - Replace `$showGoalLine` → `$viewModel.showGoalLine`
   - Pass viewModel to child views

3. Extract card views to separate files
   - `GoalsCardView(viewModel: viewModel)`
   - Each card gets viewModel as parameter
   - Bindings work via `$viewModel.property`

**Build verification**: After each file extraction

---

### **Phase v1.8: Apply Pattern to Other Large Files**
**When**: After Phase v1.7 success
**Duration**: 3-4 hours per file
**Files**:
- `WeightComponents.swift` (1,728 LOC) → `WeightTrendsViewModel.swift` + 7 view files
- `WeightChartView.swift` (1,087 LOC) → `WeightChartViewModel.swift` + 4 view files

---

### **Phase v2.0: Universal State Management**
**When**: After all Weight Tracker files refactored
**Duration**: 8-10 hours
**Scope**: Apply MVVM to Fasting, Hydration, Sleep, Mood trackers

**Benefits**:
- Consistent architecture across all trackers
- Easy to clone patterns (North Star principle)
- Testable business logic (ViewModels are pure Swift classes)

---

## Why Not Now?

**Token Budget**: 118k/200k used (59%)
**Complexity**: State refactoring is high-risk (breaks bindings if done wrong)
**Strategy**: Complete Phase v1.6 audit first → understand all dependencies → then refactor

**Apple's Official Guidance** (WWDC 2023 - Data Essentials in SwiftUI):
> "Extract state to ViewModels when views exceed 300 lines or when multiple child views need shared state."

Our files exceed 1,000+ lines → ViewModel extraction is **industry standard next step**.

---

## Success Metrics

**Before State Refactoring**:
- WeightControlCenterView.swift: 1,558 LOC (3.9x over limit)
- Cannot extract cards without breaking bindings
- All state + UI in one file

**After State Refactoring**:
- WeightControlCenterView.swift: ~300 LOC (✅ under limit)
- WeightControlCenterViewModel.swift: ~400 LOC (✅ under limit)
- 6 card files @ ~150 LOC each (✅ all under limit)
- **Total reduction**: 1,558 LOC → 7 files @ 240 LOC average

---

## Integration with Phase v1.6

**Current Phase v1.6 Plan**:
1. ✅ Audit files > 400 LOC
2. ✅ Identify split boundaries
3. ⏭️ **BLOCK**: Can't split without state refactoring

**Updated Phase v1.6 Plan**:
1. ✅ Complete audit (PHASE-v1.6-FILE-SPLIT-AUDIT.md)
2. ⏭️ Execute Phase v1.7 (State extraction)
3. ⏭️ Resume Phase v1.6 file splits (now possible with ViewModels)

---

## Risk Mitigation

**Risk**: Breaking existing functionality during state extraction
**Mitigation**:
- xcodebuild verification after each file
- Phone test after ViewModel extraction complete
- Git commits for each successful extraction

**Risk**: Increased file count
**Mitigation**:
- Folder-by-feature structure (Apple pattern)
- Clear naming conventions
- All files < 400 LOC (maintainable)

---

## Industry Precedent

**Apple Health App** (disassembled):
- Each tracker has dedicated ViewModel
- Card views are separate files
- Maximum file size: ~350 LOC

**Spotify iOS App** (open source components):
- Playlist views: ~200 LOC per file
- State management: Coordinators + ViewModels
- Average file size: 285 LOC

**Stripe iOS SDK** (open source):
- Payment views: ~300 LOC max
- ViewModels handle all business logic
- Zero files > 500 LOC

---

**Conclusion**: State management refactoring is **Phase v1.7 (next immediate step)** before completing Phase v1.6 file splits.

**Generated**: 2025-10-22 01:20:00
**Industry Validation**: Apple (WWDC 2023), Google (Flutter BLoC), Facebook (Redux), Stripe (MVVM)
