# Phase v1.7: ViewModel Extraction - Detailed Execution Plan
**Date**: 2025-10-22
**Priority**: HIGH (blocks Phase v1.6 file splits)
**Status**: Ready to execute
**Estimated Duration**: 3-4 hours

---

## State Audit Complete ✅

**File**: `WeightControlCenterView.swift` (1,803 LOC)
**State Variables Count**: 30 @State properties + 10 @AppStorage properties + 5 @ObservedObject references

### State Inventory (Lines 221-287):

#### **Environment/Injected (Keep in View)**:
```swift
@Environment(\.dismiss) var dismiss                                   // Line 221
@ObservedObject var weightManager: WeightManager                      // Line 222
@EnvironmentObject var behavioralScheduler: BehavioralNotificationScheduler  // Line 223
@Binding var showGoalLine: Bool                                       // Line 224
@Binding var weightGoal: Double                                       // Line 225
```

#### **Singleton Managers (Keep as-is)**:
```swift
@ObservedObject private var optOutManager = ContentOptOutManager.shared         // Line 228
@ObservedObject private var cardManager = TrackerCards.shared                   // Line 231
@ObservedObject private var progressStoryCardManager = ProgressStoryCards.shared // Line 234
```

#### **State to Move to ViewModel** (30 properties):

**Card Management State**:
```swift
@AppStorage("weightControlCenterCardOrder") private var cardOrderData: Data  // Line 237
@State private var cardOrder: [ControlCenterCardType]                      // Line 238
@State private var draggedCard: ControlCenterCardType?                     // Line 241
@AppStorage("controlCenterExpandedCards") private var expandedCardsData: Data // Line 244
@State private var expandedCards: Set<String>                              // Line 245
```

**Badge/Interaction State**:
```swift
@State private var currentHighlightedItemIndex: Int                         // Line 248
@State private var highlightedItemID: String?                              // Line 249
@State private var scrollViewProxy: ScrollViewProxy?                       // Line 250
@State private var badgeScale: CGFloat                                     // Line 251
```

**Goals State**:
```swift
@State private var weightGoalString: String                                // Line 254
```

**Sync State** (10 properties):
```swift
@State private var localSyncEnabled: Bool                                  // Line 257
@State private var userSyncPreference: Bool                                // Line 258
@State private var isSyncing: Bool                                         // Line 259
@State private var showingSyncAlert: Bool                                  // Line 260
@State private var syncMessage: String                                     // Line 261
@State private var hasHealthKitPermission: Bool                            // Line 262
@State private var permissionStatusMessage: String                         // Line 263
@State private var canEnableSync: Bool                                     // Line 264
@State private var lastSyncStatus: String                                  // Line 265
@State private var showingWeightSyncDetails: Bool                          // Line 266
@State private var showingSyncPreferenceDialog: Bool                       // Line 267
```

**Experience Opt-Out State** (5 @AppStorage):
```swift
@AppStorage("experienceOptOut_trackerCards") private var optOutTrackerCards: Bool  // Line 271
@AppStorage("experienceOptOut_educationalInsights") private var optOutEducationalInsights: Bool  // Line 272
@AppStorage("experienceOptOut_behavioralNudges") private var optOutBehavioralNudges: Bool  // Line 273
@AppStorage("experienceOptOut_motivationalMessages") private var optOutMotivationalMessages: Bool  // Line 274
@AppStorage("experienceOptOut_progressSummaries") private var optOutProgressSummaries: Bool  // Line 275
```

**Content Opt-Out State**:
```swift
@AppStorage("optedOutContentItems") private var optedOutContentData: Data  // Line 279
@State private var optedOutContentItems: [ContentItem]                     // Line 280
```

**Alert State**:
```swift
@State private var showingRestoreAllAlert                                  // Line 287
```

---

## Methods to Move to ViewModel (Lines 289-1533)

### **Computed Properties** (1):
- `shouldShowRestoreButton: Bool` (Lines 299-321)

### **Helper Methods** (25):
- `loadCardOrder()` (Lines 1159-1193)
- `saveCardOrder()` (Lines 1195-1199)
- `isCardExpanded()` (Lines 1124-1126)
- `toggleCardExpansion()` (Lines 1129-1136)
- `loadExpandedCards()` (Lines 1139-1148)
- `saveExpandedCards()` (Lines 1151-1155)
- `syncWithHealthKit()` (Lines 1203-1233)
- `updatePermissionStatus()` (Lines 1235-1250)
- `updateToggleState()` (Lines 1252-1258)
- `loadLastSyncStatus()` (Lines 1260-1281)
- `performSync()` (Lines 1283-1316)
- `performHistoricalSync()` (Lines 1318-1349)
- `performFutureOnlySync()` (Lines 1351-1364)
- `hasCompletedInitialImport()` (Lines 1366-1368)
- `markInitialImportCompleted()` (Lines 1370-1373)
- `formatWeightGoalInput()` (Lines 1379-1420)
- `visuallyOrderedOptedOutItems` (Lines 1426-1443)
- `cycleToNextOptedOutItem()` (Lines 1447-1488)
- `loadOptedOutContent()` (Lines 1493-1497)
- `saveOptedOutContent()` (Lines 1500-1504)
- `optOutContent()` (Lines 1511-1519)
- `optInContent()` (Lines 1523-1526)
- `isContentOptedOut()` (Lines 1531-1533)
- `restoreAllToDefault()` (Lines 1000-1026)

---

## Execution Steps

### **Step 1: Create WeightControlCenterViewModel.swift** (~500 LOC)

```swift
import SwiftUI
import Combine

/// ViewModel for Weight Control Center
/// Industry Pattern: MVVM (Apple WWDC 2023 recommendation)
/// Extracts state and business logic from WeightControlCenterView
@MainActor
class WeightControlCenterViewModel: ObservableObject {
    // MARK: - Dependencies (Injected)

    let weightManager: WeightManager
    let behavioralScheduler: BehavioralNotificationScheduler

    // Singleton managers (pass-through)
    let optOutManager = ContentOptOutManager.shared
    let cardManager = TrackerCards.shared
    let progressStoryCardManager = ProgressStoryCards.shared

    // MARK: - Published State (was @State in View)

    // Card Management
    @Published var cardOrder: [ControlCenterCardType] = [.goals, .notifications, .insights, .sync, .history, .experience]
    @Published var draggedCard: ControlCenterCardType?
    @Published var expandedCards: Set<String> = []

    // Badge/Interaction
    @Published var currentHighlightedItemIndex: Int = 0
    @Published var highlightedItemID: String?
    @Published var scrollViewProxy: ScrollViewProxy?
    @Published var badgeScale: CGFloat = 1.0

    // Goals
    @Published var weightGoalString: String = ""

    // Sync State
    @Published var localSyncEnabled: Bool = true
    @Published var userSyncPreference: Bool = true
    @Published var isSyncing: Bool = false
    @Published var showingSyncAlert: Bool = false
    @Published var syncMessage: String = ""
    @Published var hasHealthKitPermission: Bool = false
    @Published var permissionStatusMessage: String = ""
    @Published var canEnableSync: Bool = true
    @Published var lastSyncStatus: String = ""
    @Published var showingWeightSyncDetails: Bool = false
    @Published var showingSyncPreferenceDialog: Bool = false

    // Experience Opt-Out
    @Published var optOutTrackerCards: Bool = false
    @Published var optOutEducationalInsights: Bool = false
    @Published var optOutBehavioralNudges: Bool = false
    @Published var optOutMotivationalMessages: Bool = false
    @Published var optOutProgressSummaries: Bool = false

    // Content Opt-Out
    @Published var optedOutContentItems: [ContentItem] = []

    // Alerts
    @Published var showingRestoreAllAlert = false

    // MARK: - Private Properties (was @AppStorage in View)

    private let userDefaults = UserDefaults.standard
    private let hasCompletedInitialImportKey = "weightHasCompletedInitialImport"

    // AppStorage keys
    private let cardOrderKey = "weightControlCenterCardOrder"
    private let expandedCardsKey = "controlCenterExpandedCards"
    private let optedOutContentKey = "optedOutContentItems"

    // Experience opt-out keys
    private let optOutTrackerCardsKey = "experienceOptOut_trackerCards"
    private let optOutEducationalInsightsKey = "experienceOptOut_educationalInsights"
    private let optOutBehavioralNudgesKey = "experienceOptOut_behavioralNudges"
    private let optOutMotivationalMessagesKey = "experienceOptOut_motivationalMessages"
    private let optOutProgressSummariesKey = "experienceOptOut_progressSummaries"

    // MARK: - Initialization

    init(weightManager: WeightManager, behavioralScheduler: BehavioralNotificationScheduler) {
        self.weightManager = weightManager
        self.behavioralScheduler = behavioralScheduler

        // Load persisted state
        loadCardOrder()
        loadExpandedCards()
        loadOptedOutContent()
        loadExperienceOptOuts()
    }

    // MARK: - Computed Properties

    var shouldShowRestoreButton: Bool {
        let hasCategoryOptOuts = optOutTrackerCards ||
                                 optOutEducationalInsights ||
                                 optOutBehavioralNudges ||
                                 optOutMotivationalMessages ||
                                 optOutProgressSummaries

        let hasIndividualOptOuts = !optOutManager.optedOutContentItems.isEmpty

        let hasHiddenTrackerCards = TrackerCardType.allCases.contains { cardType in
            !cardManager.isCardVisible(cardType)
        }

        let hasHiddenProgressStoryCards = ProgressStoryCardType.allCases.contains { cardType in
            !progressStoryCardManager.isCardVisible(cardType)
        }

        return hasCategoryOptOuts || hasIndividualOptOuts || hasHiddenTrackerCards || hasHiddenProgressStoryCards
    }

    var visuallyOrderedOptedOutItems: [ContentItem] {
        let categoryOrder: [ContentCategory] = [
            .educationalInsights,
            .behavioralNudges,
            .motivationalMessages,
            .progressSummaries
        ]

        var orderedItems: [ContentItem] = []
        for category in categoryOrder {
            let itemsInCategory = optOutManager.optedOutContentItems.filter { $0.category == category }
            orderedItems.append(contentsOf: itemsInCategory)
        }

        return orderedItems
    }

    // MARK: - Public Methods (Business Logic)

    // [All 25 helper methods moved here - copy exact implementations from lines 1000-1533]
    // See original file for method implementations
}
```

**File Size Estimate**: ~500 LOC (all state + all methods)

---

### **Step 2: Update WeightControlCenterView.swift** (~1,300 LOC → target ~400 LOC)

**Changes**:
1. Replace state variables with ViewModel reference
2. Update all bindings: `$showGoalLine` → `$viewModel.showGoalLine`
3. Remove all helper methods (now in ViewModel)
4. Pass ViewModel to child views if needed

**Key Updates**:

```swift
struct WeightControlCenterView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel: WeightControlCenterViewModel
    @Binding var showGoalLine: Bool  // Parent binding (keep)
    @Binding var weightGoal: Double  // Parent binding (keep)

    init(weightManager: WeightManager,
         showGoalLine: Binding<Bool>,
         weightGoal: Binding<Double>) {
        _viewModel = StateObject(wrappedValue: WeightControlCenterViewModel(
            weightManager: weightManager,
            behavioralScheduler: BehavioralNotificationScheduler.shared
        ))
        _showGoalLine = showGoalLine
        _weightGoal = weightGoal
    }

    var body: some View {
        // All UI code stays the same
        // Just replace references:
        // OLD: $localSyncEnabled
        // NEW: $viewModel.localSyncEnabled
    }
}
```

---

### **Step 3: Update All Binding References** (Find/Replace)

**Pattern**: `$stateVariable` → `$viewModel.stateVariable`

**Examples**:
- `Toggle(isOn: $localSyncEnabled)` → `Toggle(isOn: $viewModel.localSyncEnabled)`
- `TextField("Enter goal", text: $weightGoalString)` → `TextField("Enter goal", text: $viewModel.weightGoalString)`
- `.alert("Sync Status", isPresented: $showingSyncAlert)` → `.alert("Sync Status", isPresented: $viewModel.showingSyncAlert)`

**Find/Replace List** (30 replacements):
```
$cardOrder                     → $viewModel.cardOrder
$draggedCard                   → $viewModel.draggedCard
$expandedCards                 → (no change - computed via method)
$currentHighlightedItemIndex   → $viewModel.currentHighlightedItemIndex
$highlightedItemID             → $viewModel.highlightedItemID
$badgeScale                    → $viewModel.badgeScale
$weightGoalString              → $viewModel.weightGoalString
$localSyncEnabled              → $viewModel.localSyncEnabled
$userSyncPreference            → $viewModel.userSyncPreference
$showingSyncAlert              → $viewModel.showingSyncAlert
$showingSyncPreferenceDialog   → $viewModel.showingSyncPreferenceDialog
$showingRestoreAllAlert        → $viewModel.showingRestoreAllAlert
```

---

### **Step 4: Update Method Calls** (Find/Replace)

**Pattern**: `methodName()` → `viewModel.methodName()`

**Examples**:
- `loadCardOrder()` → `viewModel.loadCardOrder()`
- `syncWithHealthKit()` → `viewModel.syncWithHealthKit()`
- `formatWeightGoalInput(newValue)` → `viewModel.formatWeightGoalInput(newValue)`

---

### **Step 5: Build Verification**

After each step:
```bash
xcodebuild -scheme FastingTracker -sdk iphoneos -configuration Debug build
```

**Expected Result**: Clean build with NO errors

---

### **Step 6: Extract Card Views (Optional - Future Phase)**

After ViewModel extraction is successful and verified:

**Extract each card to separate file**:
- `GoalsCardView.swift` (~150 LOC)
- `SyncCardView.swift` (~200 LOC)
- `ExperienceCardView.swift` (~250 LOC)
- `NotificationsCardView.swift` (~50 LOC)
- `InsightsCardView.swift` (~50 LOC)
- `HistoryCardView.swift` (~50 LOC)

**Pattern**:
```swift
struct GoalsCardView: View {
    @ObservedObject var viewModel: WeightControlCenterViewModel
    @Binding var showGoalLine: Bool
    @Binding var weightGoal: Double

    var body: some View {
        // Copy goalsCardContent from original file
        // Bindings already use $viewModel.property pattern
    }
}
```

---

## Success Metrics

**Before**:
- WeightControlCenterView.swift: 1,803 LOC
- All state in view
- Cannot extract cards without breaking bindings

**After Step 5** (ViewModel extraction):
- WeightControlCenterView.swift: ~1,300 LOC (still over limit but functional)
- WeightControlCenterViewModel.swift: ~500 LOC
- All bindings work via ViewModel
- **Can now extract cards** (Step 6)

**After Step 6** (Card extraction):
- WeightControlCenterView.swift: ~400 LOC ✅
- WeightControlCenterViewModel.swift: ~500 LOC ✅
- 6 card files @ ~100-250 LOC each ✅
- **Total**: 8 files, all under limit

---

## Risk Mitigation

**Risk**: Breaking bindings during refactor
**Mitigation**: Build after each step (Steps 1-5 are atomic)

**Risk**: Losing AppStorage persistence
**Mitigation**: ViewModel loads from same UserDefaults keys

**Risk**: Performance issues (ViewModel is @MainActor)
**Mitigation**: All UI updates already on main thread, no change

---

## Next Session Execution Checklist

□ Step 1: Create WeightControlCenterViewModel.swift
□ Step 2: Add @StateObject in WeightControlCenterView
□ Step 3: Replace 30 binding references ($var → $viewModel.var)
□ Step 4: Replace 25 method calls (method() → viewModel.method())
□ Step 5: Build verification + commit
□ Step 6: Extract cards (future phase)

**Estimated Time**: 3-4 hours for Steps 1-5

---

**Generated**: 2025-10-22 01:25:00
**Ready to Execute**: Yes ✅
**Blockers**: None
**Industry Validation**: Apple WWDC 2023 - MVVM pattern for views > 300 LOC
