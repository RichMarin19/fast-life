# Fast LIFe - Testing Documentation

## Overview
This document describes the testing infrastructure, patterns, and best practices for Fast LIFe.

**Phase:** 0.5 - Groundwork + Tool Optimization
**Last Updated:** October 17, 2025 (Tool optimization complete)

---

## ⚡ Phase 0.5 Tool Optimizations

**Date Completed:** October 17, 2025
**Improvements:** CI performance (50% faster), custom quality rules, progress tracking

### What Was Optimized:

1. **CI Pipeline Caching** - Added Homebrew and DerivedData caching
   - Saves ~60 seconds on SwiftLint installation
   - Saves ~3-5 minutes on build (cache hit)
   - Total speedup: **8-10 min → 3-4 min (50% faster)**

2. **Custom SwiftLint Rules** - Enforces North Star design system
   - `no_raw_hex_colors`: Must use `Theme.ColorToken` (error severity)
   - `button_accessibility_hint`: Reminds to add accessibility labels
   - `prefer_is_empty`: Use `.isEmpty` instead of `.count == 0`
   - `todo_with_context`: TODOs must have ticket/date

3. **Modern Swift 5.9+ Rules** - Enhanced code quality
   - `multiline_function_chains`
   - `multiline_parameters`
   - `multiline_arguments`
   - `prefer_self_in_static_references`
   - `strict_fileprivate`

4. **LOC Trend Tracking** - Progress visibility
   - Shows top 10 largest files in gate output
   - Color-coded by threshold (green/yellow/red)
   - Logs metrics to CSV in CI environment

5. **CI Workflow Enhancements**
   - Manual trigger support (`workflow_dispatch`)
   - Concurrency control (cancels outdated runs)
   - Smarter SwiftLint installation (skip if cached)

### Impact on Development:

- **Faster Feedback:** CI runs complete 50% faster
- **Design System Enforcement:** Custom rules catch raw hex values before PR
- **Accessibility Reminders:** Warns about missing accessibility labels
- **Progress Tracking:** See refactoring progress (652 → 250 LOC goals)

---

## Test Infrastructure

### Directory Structure
```
FastingTrackerTests/
├── FastingTrackerTests.swift          # Base test case class
├── Managers/                          # Manager unit tests
│   └── WeightManagerTests.swift       # 30+ unit tests
├── Helpers/                           # Test utilities
│   └── TestHelpers.swift              # Date helpers, assertions, mocks
└── Fixtures/                          # JSON fixtures and test data
```

### Test Target Setup
- **Target:** FastingTrackerTests
- **Platform:** iOS 17.5+
- **Framework:** XCTest
- **Host App:** FastingTracker

---

## Test Patterns

### 1. Arrange-Act-Assert (AAA)
All tests follow the AAA pattern for clarity:

```swift
func testAddWeightEntry_AddsToCollection() {
    // Given (Arrange)
    let entry = WeightEntry(date: Date(), weight: 150.0, source: .manual)

    // When (Act)
    weightManager.addWeightEntry(entry)

    // Then (Assert)
    XCTAssertEqual(weightManager.weightEntries.count, 1)
}
```

### 2. Test Naming Convention
Format: `test<MethodName>_<Scenario>_<ExpectedResult>`

Examples:
- `testAddWeightEntry_AddsToCollection`
- `testWeightTrend_ReturnsNilWithInsufficientData`
- `testWouldCreateDuplicate_DetectsSameWeight`

### 3. Base Test Class
All tests inherit from `FastingTrackerTests` for common setup/teardown:

```swift
class MyManagerTests: FastingTrackerTests {
    var manager: MyManager!

    override func setUp() {
        super.setUp()
        manager = MyManager()
    }

    override func tearDown() {
        manager = nil
        super.tearDown()
    }
}
```

---

## Test Helpers

### Date Helpers
```swift
// Create test dates
let date = Date.testDate(year: 2025, month: 10, day: 17, hour: 12)

// Date arithmetic
let yesterday = Date().minusDays(1)
let tomorrow = Date().plusDays(1)
let twoHoursAgo = Date().minusHours(2)
```

### Custom Assertions
```swift
// Date comparison with tolerance
XCTAssertEqualDates(date1, date2, accuracy: 1.0)

// Floating point comparison with percentage
XCTAssertEqualWithin(150.0, 151.0, percent: 0.01)
```

### Mock Data Generators
```swift
// Generate date ranges
let dates = TestDataGenerator.dateRange(from: startDate, count: 7, intervalHours: 24)

// Random test data
let weights = TestDataGenerator.randomWeights(count: 10, baseWeight: 70.0)
let amounts = TestDataGenerator.randomHydrationAmounts(count: 10)
```

---

## Test Coverage Strategy

### Phase 0 Baseline (Current)
- **Manager Tests:** Core business logic
- **Coverage Target:** 30+ tests minimum
- **Focus:** Happy paths + edge cases

**WeightManagerTests (30 tests):**
- ✅ Add/Delete operations
- ✅ Duplicate detection
- ✅ Unit conversions
- ✅ Statistics calculations
- ✅ Edge cases (extreme values, empty states)

### Phase 1 Expansion (Week 1)
- Fasting Manager tests
- Hydration Manager tests
- Target: 50+ total tests

### Phase 2 Comprehensive (Week 2)
- All Manager tests
- UI smoke tests
- Snapshot tests (key views)
- Target: 75% Manager coverage

---

## Running Tests

### Command Line
```bash
# Run all tests
xcodebuild test \
  -project FastingTracker.xcodeproj \
  -scheme FastingTracker \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro'

# Run specific test class
xcodebuild test \
  -project FastingTracker.xcodeproj \
  -scheme FastingTracker \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  -only-testing:FastingTrackerTests/WeightManagerTests
```

### Xcode
1. Open FastingTracker.xcodeproj
2. Select FastingTracker scheme
3. Press ⌘U to run all tests
4. View results in Test Navigator (⌘6)

### CI Pipeline
Tests run automatically on every push:
- Lint & LOC gate → Build → Test
- Results uploaded as artifacts
- Code coverage tracked

---

## Test Data Patterns

### Golden Files (Future)
Store deterministic test data as JSON:
```swift
let fixture = TestDataGenerator.loadFixture("weight_entries_7days.json")
```

### In-Memory Test Data
For unit tests, create data programmatically:
```swift
let entries = (0..<7).map { i in
    WeightEntry(
        date: Date().minusDays(i),
        weight: 150.0 - Double(i),
        source: .manual
    )
}
```

---

## Testing Best Practices

### ✅ DO
- Test one behavior per test
- Use descriptive test names
- Test edge cases (empty, nil, extreme values)
- Clean up state in tearDown
- Use test helpers for common operations
- Keep tests fast (no network, no sleep)

### ❌ DON'T
- Test Apple frameworks (SwiftUI, HealthKit)
- Test implementation details
- Share state between tests
- Use `sleep()` or arbitrary delays
- Test multiple behaviors in one test
- Rely on test execution order

---

## Async Testing

### Testing @MainActor Code
```swift
@MainActor
func testMainActorMethod() async {
    // Test code runs on main actor
    await manager.asyncMethod()
    XCTAssertEqual(manager.value, expectedValue)
}
```

### Testing Async Operations
```swift
func testAsyncOperation() {
    let expectation = XCTestExpectation(description: "Operation completes")

    manager.asyncMethod { result in
        XCTAssertEqual(result, expected)
        expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
}
```

---

## CI Integration

### GitHub Actions Workflow
```yaml
- name: Run unit tests
  run: |
    xcodebuild test \
      -project FastingTracker.xcodeproj \
      -scheme FastingTracker \
      -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
      -enableCodeCoverage YES
```

### Test Failure Policy
- **CI:** Tests must pass for PR merge
- **Flaky Tests:** Quarantine and fix within 48 hours
- **Coverage:** Track but don't block (70%+ target)

---

## Future Testing Strategy

### Week 2 Additions
- [ ] Snapshot tests (SwiftUI views)
- [ ] UI tests (critical flows)
- [ ] Performance tests (timer accuracy)

### Week 3 Additions
- [ ] Accessibility tests
- [ ] Localization tests
- [ ] Integration tests (HealthKit mocks)

---

## Test Metrics

### Current State (Phase 0)
- **Total Tests:** 30+
- **Test Classes:** 1 (WeightManagerTests)
- **Coverage:** Baseline (Weight Manager)
- **CI Status:** ✅ Ready

### Target State (Phase 2)
- **Total Tests:** 75+
- **Test Classes:** 5+ (All Managers)
- **Coverage:** 70%+ critical paths
- **CI Status:** ✅ Green on all PRs

---

## Troubleshooting

### Common Issues

**Test Target Not Found:**
```bash
# Verify test target exists
xcodebuild -project FastingTracker.xcodeproj -list
```

**Tests Not Running in CI:**
- Check scheme is shared (xcshareddata)
- Verify simulator availability
- Check code signing settings

**Flaky Tests:**
- Add deterministic waits
- Use XCTestExpectation properly
- Avoid date/time dependencies

---

## References

- [XCTest Documentation](https://developer.apple.com/documentation/xctest)
- [Testing SwiftUI](https://developer.apple.com/documentation/swiftui/testing-your-apps-in-swiftui)
- [CI Best Practices](https://developer.apple.com/documentation/xcode/running-tests-and-interpreting-results)

---

**Next Steps:**
1. ✅ Phase 0 complete - 30+ baseline tests
2. ⏳ Phase 1 - Expand to all Managers
3. ⏳ Phase 2 - Add UI and snapshot tests
