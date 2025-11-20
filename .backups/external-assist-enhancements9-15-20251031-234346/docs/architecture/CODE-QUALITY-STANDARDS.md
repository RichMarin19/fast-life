# Fast LIFe - Code Quality Standards

> **Purpose:** LOC refactoring policy and code quality guidelines
>
> **Scope:** All Swift files in Fast LIFe project
>
> **Last Updated:** October 16, 2025
>
> **Status:** Active policy for all development

---

## 📏 LINES OF CODE (LOC) POLICY

### Mandatory Refactor Triggers

**🚨 400 LOC = REFACTOR REQUIRED**
- **Policy:** Any Swift file exceeding 400 lines MUST be refactored
- **Priority:** HIGH - refactor before adding new features
- **No Exceptions:** Unless documented and approved by technical lead
- **Rationale:** SwiftUI compilation timeouts at ~500 LOC, maintainability decreases after 400 LOC

**Current Violations:**
- ❌ ContentView.swift (Fasting): 652 LOC (252 LOC over limit)
- ❌ HydrationTrackingView.swift: 584 LOC (184 LOC over limit)

**Action Required:** Phase C refactoring for both files

### Target Range

**🎯 250-300 LOC = OPTIMAL**
- **Goal:** Aim for this range whenever possible
- **Sweet Spot:** 250-300 LOC balances readability with maintainability
- **Rationale:** Files in this range are easy to understand, test, and modify

**Current Best Practices:**
- ✅ WeightTrackingView.swift: 257 LOC (GOLD STANDARD)
- ✅ MoodTrackingView.swift: 97 LOC (OPTIMAL)
- ⚠️ SleepTrackingView.swift: 304 LOC (4 LOC over target - acceptable)

### Performance Preservation

**⚖️ User Experience > Code Metrics**
- **Rule:** Never sacrifice noticeable performance for LOC reduction
- **Testing Required:** Measure before/after refactoring
- **Metrics:** Frame rate, memory usage, battery impact, response time
- **Example:** Don't split timer logic if it introduces lag

**Performance Testing Checklist:**
- [ ] 60fps scrolling maintained
- [ ] <100ms response to user interactions
- [ ] Memory usage stable (no leaks)
- [ ] Battery impact unchanged
- [ ] No visual glitches or jank

---

## 🛠️ REFACTORING PROCESS

### When 400 LOC Exceeded

**Step 1: Analyze File Structure (30 minutes)**
- [ ] Read entire file
- [ ] Identify logical sections
- [ ] Note @ViewBuilder computed properties
- [ ] List @State/@Published variables
- [ ] Check for code duplication

**Step 2: Plan Component Extraction (1 hour)**
- [ ] Group related code into components
- [ ] Name components clearly (noun-based)
- [ ] Identify required parameters
- [ ] Identify bindings needed
- [ ] Sketch component hierarchy

**Step 3: Extract Largest Component First (2-3 hours)**
- [ ] Create new .swift file
- [ ] Copy code to new file
- [ ] Add required parameters
- [ ] Add bindings
- [ ] Test component in isolation

**Step 4: Integrate Component (1 hour)**
- [ ] Import component in main view
- [ ] Replace extracted code with component call
- [ ] Pass required parameters
- [ ] Test integration
- [ ] Verify no regressions

**Step 5: Repeat for Remaining Components (varies)**
- [ ] Extract second-largest component
- [ ] Extract third-largest component
- [ ] Continue until main view ≤300 LOC

**Step 6: Verify Quality (1 hour)**
- [ ] Run full build (0 errors, 0 warnings)
- [ ] Test all functionality
- [ ] Verify performance unchanged
- [ ] Update documentation
- [ ] Commit with descriptive message

**Total Time Estimate:** 6-10 hours per file (depending on complexity)

---

## 📊 LOC MONITORING

### Current State (October 16, 2025)

| File | Current LOC | Target LOC | Status | Priority |
|------|-------------|------------|--------|----------|
| **ContentView.swift** (Fasting) | 652 | 300 | ❌ OVER LIMIT | HIGH |
| **HydrationTrackingView.swift** | 584 | 300 | ❌ OVER LIMIT | HIGH |
| **SleepTrackingView.swift** | 304 | 300 | ✅ NEARLY OPTIMAL | LOW |
| **MoodTrackingView.swift** | 97 | 300 | ✅ OPTIMAL | NONE |
| **WeightTrackingView.swift** | 257 | 300 | ✅ OPTIMAL | NONE |
| **TOTAL** | 1,894 | 1,200 | | |

**Reduction Needed:** 694 LOC (37%)

### Tracking LOC Over Time

**Method 1: Manual Check**
```bash
# Count LOC for specific file
wc -l /path/to/FastingTracker/ContentView.swift

# Count LOC for all trackers
wc -l /path/to/FastingTracker/*TrackingView.swift
```

**Method 2: Git Hook (Future)**
```bash
# Pre-commit hook to check LOC
# Prevent commits if file >400 LOC
# (To be implemented)
```

**Method 3: CI/CD Check (Future)**
```bash
# Build pipeline fails if LOC policy violated
# Generates LOC report on each commit
# (To be implemented)
```

---

## 🏗️ ARCHITECTURE STANDARDS

### MVVM Pattern (Required)

**View Layer:**
- **Responsibility:** UI presentation only
- **Size:** ≤300 LOC per view
- **State:** @State for UI-only state, @ObservedObject for shared state
- **No Business Logic:** All logic in Manager classes

**ViewModel (Manager) Layer:**
- **Responsibility:** Business logic, data operations
- **Pattern:** @Published properties for reactive updates
- **Threading:** All @Published updates on main thread
- **Example:** WeightManager, FastingManager, HydrationManager

**Model Layer:**
- **Responsibility:** Data structures only
- **Pattern:** Struct with Codable conformance
- **Immutability:** Use structs, not classes (unless required)
- **Example:** WeightEntry, FastingSession, HydrationEntry

**Industry Standards:**
- Apple MVVM Guidelines: https://developer.apple.com/documentation/swiftui/managing-model-data-in-your-app
- MVVM Best Practices: Separate concerns, testable architecture

### Component Extraction Guidelines

**When to Extract:**
- [ ] Section >50 LOC
- [ ] Reusable across multiple views
- [ ] Logically independent
- [ ] Testable in isolation
- [ ] Clear responsibility

**How to Name:**
- Use nouns (not verbs)
- Be specific (not generic)
- Include context (e.g., "FastingTimerView" not "TimerView")
- Good: `CurrentWeightCard`, `WeightChartView`, `WeightStatsView`
- Bad: `DataView`, `ChartComponent`, `Stats`

**Component Size:**
- Target: 50-150 LOC per component
- Maximum: 300 LOC per component
- If >300 LOC, extract sub-components

**Example Extraction:**
```swift
// BEFORE: Monolithic view (652 LOC)
struct ContentView: View {
    var body: some View {
        VStack {
            // 85 lines of timer UI
            // 38 lines of goal UI
            // 85 lines of controls UI
            // 39 lines of history UI
        }
    }
}

// AFTER: Component extraction (252 LOC main + 5 components)
struct ContentView: View {
    var body: some View {
        VStack {
            FastingTimerView()      // 85 LOC in separate file
            FastingGoalView()       // 38 LOC in separate file
            FastingControlsView()   // 85 LOC in separate file
            FastingHistoryView()    // 39 LOC in separate file
        }
    }
}
```

---

## 🎯 CODE QUALITY CHECKLIST

### Before Committing Code

**Functionality:**
- [ ] Feature works as expected
- [ ] All edge cases handled
- [ ] Error states handled gracefully
- [ ] Performance acceptable (60fps, <100ms response)

**Code Quality:**
- [ ] File LOC ≤400 (preferably ≤300)
- [ ] MVVM pattern followed
- [ ] No code duplication
- [ ] Clear variable/function names
- [ ] Comments explain "why" not "what"

**Testing:**
- [ ] Manual testing complete
- [ ] All screen sizes tested (SE, standard, Pro Max)
- [ ] Dark mode tested
- [ ] VoiceOver tested (if applicable)
- [ ] No regressions in existing features

**Build Quality:**
- [ ] Build succeeds (Cmd+B)
- [ ] 0 errors
- [ ] 0 warnings
- [ ] No SwiftUI preview issues

**Documentation:**
- [ ] HANDOFF.md updated (if applicable)
- [ ] Inline comments added (complex logic)
- [ ] Git commit message descriptive

---

## 📚 REFACTORING EXAMPLES

### Example 1: Weight Tracker (Successful)

**Before Phase 3a:**
- WeightTrackingView.swift: 2,561 LOC
- Monolithic structure
- Hard to maintain
- SwiftUI compilation issues

**After Phase 3a:**
- WeightTrackingView.swift: 257 LOC (90% reduction)
- Components: CurrentWeightCard (485 LOC), WeightChartView (1,082 LOC), WeightStatsView, WeightHistoryListView
- Clean MVVM separation
- Easy to maintain
- Fast compilation

**Lessons Learned:**
- Extract largest components first (biggest impact)
- Test after each component extraction (catch regressions early)
- Component reuse saves future work (CurrentWeightCard used in multiple places)

### Example 2: Mood Tracker (Successful)

**Before Phase 3:**
- MoodTrackingView.swift: 488 LOC
- Mixed UI and logic
- Moderate complexity

**After Phase 3:**
- MoodTrackingView.swift: 97 LOC (80% reduction)
- Components: MoodEnergyCirclesView, MoodEnergyGraphsView, MoodEntryRow
- Clear component hierarchy
- Highly maintainable

**Lessons Learned:**
- Even "medium" files benefit from extraction (488→97 LOC)
- Component names should be descriptive (MoodEnergyCirclesView vs CirclesView)
- Simple views can be VERY simple (97 LOC is optimal)

### Example 3: Fasting Tracker (Pending Phase C.3)

**Current State:**
- ContentView.swift: 652 LOC
- Needs refactoring (252 LOC over limit)
- Complex timer logic
- Embedded history

**Planned Extraction:**
- FastingTimerView: ~85 LOC (lines 191-276)
- FastingGoalView: ~38 LOC (lines 300-338)
- FastingStatsView: ~13 LOC (lines 285-298)
- FastingHistoryView: ~39 LOC (lines 428-467)
- FastingControlsView: ~85 LOC (lines 341-426)
- Main view: ~250 LOC (orchestration only)

**Expected Result:**
- ContentView.swift: 250 LOC (62% reduction)
- 5 reusable components
- Easier to test timer accuracy
- Cleaner architecture

---

## ⚠️ COMMON PITFALLS

### Pitfall 1: Extracting Too Early
**Problem:** Extracting components before understanding full requirements
**Symptom:** Components need frequent modifications, breaking changes
**Solution:** Wait until requirements stable, then extract

### Pitfall 2: Over-Extraction
**Problem:** Creating too many tiny components (<20 LOC each)
**Symptom:** File navigation overhead, harder to understand flow
**Solution:** Components should be 50-150 LOC (meaningful chunks)

### Pitfall 3: Breaking State Management
**Problem:** Extracting without preserving bindings
**Symptom:** "Cannot find 'variable' in scope" errors
**Solution:** Check all @State/@Binding variables before extraction

### Pitfall 4: Duplicate UI Rendering
**Problem:** Leaving code in main view after moving to computed property
**Symptom:** UI elements appear twice (2 buttons, 2 cards)
**Solution:** REMOVE original code after moving to component

### Pitfall 5: Ignoring Performance
**Problem:** Splitting timer logic introduces lag
**Symptom:** Timer updates slowly, UI feels janky
**Solution:** Keep performance-critical code together, optimize after extraction

---

## 🎯 SUCCESS METRICS

### Project-Wide Targets

**LOC Distribution (Target):**
- 0% of files >400 LOC
- 80%+ of files ≤300 LOC
- Average file size: 200-250 LOC

**Current Status:**
- 40% of trackers >400 LOC (Fasting, Hydration)
- 60% of trackers ≤300 LOC (Weight, Sleep, Mood)
- Average: 379 LOC (too high)

**Phase C Target:**
- 0% of trackers >400 LOC ✅
- 100% of trackers ≤300 LOC ✅
- Average: 240 LOC ✅

### Quality Metrics

**Build Quality:**
- Target: 0 errors, 0 warnings
- Current: ✅ ACHIEVED (0 errors, 0 warnings)

**Code Duplication:**
- Target: <5% duplication
- Current: Unknown (needs analysis)

**Component Reuse:**
- Target: 80%+ component reuse
- Current: ~60% (TrackerScreenShell, FLCard, HealthKitNudgeView)

**Test Coverage:**
- Target: 30%+ unit test coverage
- Current: 0% (no tests yet)

---

## 📖 ADDITIONAL RESOURCES

### Apple Documentation
- [SwiftUI Views and Controls](https://developer.apple.com/documentation/swiftui/views-and-controls)
- [Managing Model Data](https://developer.apple.com/documentation/swiftui/managing-model-data-in-your-app)
- [Accessibility](https://developer.apple.com/documentation/accessibility)

### Industry Standards
- [Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/)
- [Ray Wenderlich SwiftUI Style Guide](https://github.com/raywenderlich/swift-style-guide)
- [Google Swift Style Guide](https://google.github.io/swift/)

### Fast LIFe Documentation
- [HANDOFF-REFERENCE.md](./HANDOFF-REFERENCE.md) - Component extraction patterns
- [TRACKER-AUDIT.md](./TRACKER-AUDIT.md) - Current state assessment
- [NORTH-STAR-STRATEGY.md](./NORTH-STAR-STRATEGY.md) - Visual design replication

---

## 🔄 POLICY UPDATES

### Version History

**v1.0 (October 16, 2025)**
- Initial policy creation
- 400 LOC refactor trigger established
- 250-300 LOC target range defined
- Performance preservation rule added

**Future Updates:**
- Git pre-commit hooks (LOC checking)
- CI/CD LOC reporting
- Automated LOC tracking dashboard

---

**Code Quality Standards Complete**
**Next Steps:** Apply during Phase C refactoring

**Last Updated:** October 16, 2025
**Next Review:** After Phase C completion
