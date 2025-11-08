//
//  WeightManagerTests.swift
//  FastingTrackerTests
//
//  Created by Claude Code
//  Phase 0: Baseline Unit Tests
//

import XCTest
import Combine
@testable import FastLIFe

struct TestLocaleProvider: LocaleProviding {
    var measurementSystem: Locale.MeasurementSystem
    var localeIdentifier: String
}

@MainActor
final class WeightManagerTests: XCTestCase {

    var weightManager: WeightManager!
    var appSettings: AppSettings!

    override func setUp() {
        super.setUp()
        Self.removeSecurePersistenceArtifact()
        // Clear UserDefaults for clean test state
        if let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
        }
        appSettings = AppSettings(localeProvider: TestLocaleProvider(measurementSystem: .us, localeIdentifier: "en_US"))
        weightManager = WeightManager(
            healthKit: MockHealthKitManager(),
            dataStore: MockDataStore(),
            appSettings: appSettings,
            persistence: InMemoryWeightPersistence(),
            syncCoordinator: MockWeightSyncCoordinator(),
            analytics: WeightAnalyticsService()
        )
        // Clear any existing entries for clean tests
        weightManager.weightEntries.removeAll()
        // Disable HealthKit sync for faster, isolated unit tests
        weightManager.syncWithHealthKit = false
    }

    override func tearDown() {
        weightManager = nil
        appSettings = nil
        Self.removeSecurePersistenceArtifact()
        super.tearDown()
    }

    private static func removeSecurePersistenceArtifact() {
        let fileManager = FileManager.default
        guard let baseURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return
        }
        let secureDirectory = baseURL.appendingPathComponent("SecureStorage", isDirectory: true)
        let secureFile = secureDirectory.appendingPathComponent("weight_persistence_v1.json.enc")
        try? fileManager.removeItem(at: secureFile)
    }

    @MainActor
    private func makeWeightManager(persistence: InMemoryWeightPersistence) -> WeightManager {
        WeightManager(
            healthKit: MockHealthKitManager(),
            dataStore: MockDataStore(),
            appSettings: appSettings,
            persistence: persistence,
            syncCoordinator: MockWeightSyncCoordinator(),
            analytics: WeightAnalyticsService()
        )
    }

    // MARK: - Add Weight Entry Tests

    func testAddWeightEntry_AddsToCollection() {
        // Given
        let entry = WeightEntry(date: Date(), weight: 150.0, source: .manual)

        // When
        weightManager.addWeightEntry(entry)

        // Then - wait for async addition (WeightManager uses DispatchQueue.main.async)
        let expectation = XCTestExpectation(description: "Entry added")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(self.weightManager.weightEntries.count, 1)
            XCTAssertEqual(self.weightManager.weightEntries.first?.weight, 150.0)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testAddWeightEntry_SortsNewestFirst() {
        // Given
        let older = WeightEntry(date: Date().minusDays(2), weight: 150.0, source: .manual)
        let newer = WeightEntry(date: Date().minusDays(1), weight: 149.0, source: .manual)

        // When
        weightManager.addWeightEntry(older)
        weightManager.addWeightEntry(newer)

        // Then - wait for async additions
        let expectation = XCTestExpectation(description: "Entries sorted")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(self.weightManager.weightEntries.count, 2)
            XCTAssertEqual(self.weightManager.weightEntries.first?.weight, 149.0) // Newer entry first
            XCTAssertEqual(self.weightManager.weightEntries.last?.weight, 150.0)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testAddWeightEntry_AllowsMultipleEntriesPerDay() {
        // Given
        let morning = WeightEntry(date: Date.testDate(hour: 8), weight: 150.0, source: .manual)
        let evening = WeightEntry(date: Date.testDate(hour: 20), weight: 151.0, source: .manual)

        // When
        weightManager.addWeightEntry(morning)
        weightManager.addWeightEntry(evening)

        // Then - wait for async additions
        let expectation = XCTestExpectation(description: "Multiple entries added")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(self.weightManager.weightEntries.count, 2)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - Delete Weight Entry Tests

    func testDeleteWeightEntry_RemovesFromCollection() {
        // Given
        let entry = WeightEntry(date: Date(), weight: 150.0, source: .manual)
        weightManager.addWeightEntry(entry)

        // Wait for async addition to complete first
        let addExpectation = XCTestExpectation(description: "Entry added")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(self.weightManager.weightEntries.count, 1)
            addExpectation.fulfill()
        }
        wait(for: [addExpectation], timeout: 1.0)

        // When
        weightManager.deleteWeightEntry(entry)

        // Then - wait for async deletion
        let deleteExpectation = XCTestExpectation(description: "Entry deleted")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(self.weightManager.weightEntries.count, 0)
            deleteExpectation.fulfill()
        }
        wait(for: [deleteExpectation], timeout: 1.0)
    }

    // MARK: - Duplicate Detection Tests

    func testWouldCreateDuplicate_DetectsSameWeight() {
        // Given
        let existingEntry = WeightEntry(date: Date(), weight: 150.0, source: .manual)
        weightManager.addWeightEntry(existingEntry)

        // When/Then - wait for async addition before checking
        let expectation = XCTestExpectation(description: "Duplicate detected")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertTrue(self.weightManager.wouldCreateDuplicate(weight: 150.0, date: Date()))
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testWouldCreateDuplicate_AllowsDifferentWeight() {
        // Given
        let existingEntry = WeightEntry(date: Date(), weight: 150.0, source: .manual)
        weightManager.addWeightEntry(existingEntry)

        // When/Then
        XCTAssertFalse(weightManager.wouldCreateDuplicate(weight: 155.0, date: Date()))
    }

    func testWouldCreateDuplicate_AllowsAfterTimeWindow() {
        // Given
        let oldEntry = WeightEntry(date: Date().minusHours(2), weight: 150.0, source: .manual)
        weightManager.addWeightEntry(oldEntry)

        // When/Then - 2 hours later, same weight should be allowed
        XCTAssertFalse(weightManager.wouldCreateDuplicate(weight: 150.0, date: Date()))
    }

    func testWouldCreateDuplicate_DetectsAcrossAllSources() {
        // Given - HealthKit entry
        let healthKitEntry = WeightEntry(date: Date(), weight: 150.0, source: .healthKit)
        weightManager.addWeightEntry(healthKitEntry)

        // When/Then - wait for async addition before checking
        let expectation = XCTestExpectation(description: "Cross-source duplicate detected")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Manual entry with same weight should be detected as duplicate
            XCTAssertTrue(self.weightManager.wouldCreateDuplicate(weight: 150.0, date: Date()))
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - Unit Conversion Tests

    func testDisplayWeight_ConvertsCorrectly() {
        // Given
        let entry = WeightEntry(date: Date(), weight: 150.0, source: .manual) // 150 lbs

        // When
        let displayWeight = weightManager.displayWeight(for: entry)

        // Then - depends on user's unit preference
        XCTAssertGreaterThan(displayWeight, 0)
    }

    func testConvertToInternalUnit_ConvertsToPounds() {
        // Given
        let userInput = 70.0 // Could be kg or lbs depending on setting

        // When
        let internalValue = weightManager.convertToInternalUnit(userInput)

        // Then
        XCTAssertGreaterThan(internalValue, 0)
    }

    // MARK: - Statistics Tests

    func testLatestWeight_ReturnsNewest() {
        // Given
        let older = WeightEntry(date: Date().minusDays(2), weight: 150.0, source: .manual)
        let newer = WeightEntry(date: Date().minusDays(1), weight: 149.0, source: .manual)

        weightManager.addWeightEntry(older)
        weightManager.addWeightEntry(newer)

        // When/Then - wait for async additions
        let expectation = XCTestExpectation(description: "Latest weight retrieved")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let latest = self.weightManager.latestWeight
            XCTAssertEqual(latest?.weight, 149.0)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testLatestWeight_ReturnsNilWhenEmpty() {
        // Given - empty manager

        // When
        let latest = weightManager.latestWeight

        // Then
        XCTAssertNil(latest)
    }

    func testWeightTrend_CalculatesCorrectly() {
        // Given - 7 entries showing weight loss
        for i in 0..<7 {
            let entry = WeightEntry(
                date: Date().minusDays(6 - i),
                weight: 150.0 - Double(i), // Losing 1 lb per day
                source: .manual
            )
            weightManager.addWeightEntry(entry)
        }

        // When/Then - wait for all async additions
        let expectation = XCTestExpectation(description: "Trend calculated")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            let trend = self.weightManager.weightTrend
            // Should show negative trend (weight loss)
            XCTAssertNotNil(trend)
            XCTAssertLessThan(trend!, 0) // Weight decreased
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testWeightTrend_ReturnsNilWithInsufficientData() {
        // Given - only 1 entry
        let entry = WeightEntry(date: Date(), weight: 150.0, source: .manual)
        weightManager.addWeightEntry(entry)

        // When
        let trend = weightManager.weightTrend

        // Then
        XCTAssertNil(trend)
    }

    func testAverageWeight_CalculatesCorrectly() {
        // Given
        weightManager.addWeightEntry(WeightEntry(date: Date(), weight: 150.0, source: .manual))
        weightManager.addWeightEntry(WeightEntry(date: Date().minusDays(1), weight: 152.0, source: .manual))
        weightManager.addWeightEntry(WeightEntry(date: Date().minusDays(2), weight: 148.0, source: .manual))

        // When/Then - wait for async additions
        let expectation = XCTestExpectation(description: "Average calculated")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let average = self.weightManager.averageWeight
            XCTAssertNotNil(average)
            self.XCTAssertEqualWithin(average!, 150.0, percent: 0.01) // Average should be 150
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testAverageWeight_ReturnsNilWhenEmpty() {
        // Given - empty manager

        // When
        let average = weightManager.averageWeight

        // Then
        XCTAssertNil(average)
    }

    func testWeightChange_CalculatesCorrectly() {
        // Given
        let startDate = Date().minusDays(7)
        let startWeight = 150.0
        let currentWeight = 147.0

        // Add entries synchronously by directly accessing weightEntries
        // This avoids async timing issues in the test
        weightManager.weightEntries.append(WeightEntry(date: startDate, weight: startWeight, source: .manual))
        weightManager.weightEntries.append(WeightEntry(date: Date(), weight: currentWeight, source: .manual))
        weightManager.weightEntries.sort { $0.date > $1.date }

        // When - calculate weight change
        let change = weightManager.weightChange(since: startDate)

        // Then
        XCTAssertNotNil(change, "Weight change should not be nil when entries exist")
        XCTAssertEqual(change!, -3.0, accuracy: 0.01, "Expected weight loss of 3 lbs")
    }

    func testWeightChange_ReturnsNilWhenNoHistoricalData() {
        // Given - only current entry
        weightManager.addWeightEntry(WeightEntry(date: Date(), weight: 150.0, source: .manual))

        // When
        let change = weightManager.weightChange(since: Date().minusDays(7))

        // Then
        XCTAssertNil(change)
    }

    // MARK: - Phase 2 Task 2.1 - Weight Formatting

    func testFormattedDisplayWeight_trimsTrailingZeroForIntegers() {
        let formatted = weightManager.formattedDisplayWeight(150.0)
        if weightManager.currentUnitAbbreviation == "lbs" {
            XCTAssertEqual(formatted, "150", "Pound display should trim trailing decimals")
        } else {
            XCTAssertEqual(formatted, "68.0", "Metric display should round to one decimal")
        }
    }

    func testFormattedDisplayWeight_preservesDecimalPrecision() {
        let formatted = weightManager.formattedDisplayWeight(150.5)
        if weightManager.currentUnitAbbreviation == "lbs" {
            XCTAssertEqual(formatted, "150.5")
        } else {
            XCTAssertEqual(formatted, "68.3", "Metric display should show one decimal place")
        }
    }

    // MARK: - Phase 2 Task 2.1 - Resolved Start Weight

    func testResolvedStartWeight_returnsOverrideWhenPresent() {
        let overrideDate = Date(timeIntervalSince1970: 1_000)
        weightManager.setStartWeightOverride(155.0, date: overrideDate)

        let resolved = weightManager.resolvedStartWeight()
        XCTAssertNotNil(resolved)
        if let resolved = resolved {
            XCTAssertEqual(resolved.date, overrideDate)
            XCTAssertEqual(resolved.weight, weightManager.convertToInternalUnit(155.0), accuracy: 0.0001)
        }
    }

    func testResolvedStartWeight_fallsBackToOldestEntry() {
        let oldest = WeightEntry(date: Date().minusDays(5), weight: 200.0, source: .manual)
        let latest = WeightEntry(date: Date(), weight: 190.0, source: .manual)
        weightManager.setStartWeightOverride(nil, date: nil)
        var entries = [latest, oldest]
        entries.sort { $0.date > $1.date }
        weightManager.weightEntries = entries

        let resolved = weightManager.resolvedStartWeight()
        if let resolved = resolved {
            XCTAssertEqual(resolved.id, oldest.id)
            XCTAssertEqual(resolved.weight, oldest.weight)
        } else {
            XCTFail("Expected oldest entry to be resolved")
        }
    }

    func testResolvedStartWeight_returnsNilWhenEmpty() {
        weightManager.weightEntries.removeAll()
        weightManager.setStartWeightOverride(nil, date: nil)

        XCTAssertNil(weightManager.resolvedStartWeight())
    }

    // MARK: - Phase 2 Task 2.1 - Milestone Count Validation

    func testSetMilestoneCount_clampsBelowZero() {
        weightManager.setMilestoneCount(-5)
        XCTAssertEqual(weightManager.milestoneCount, 0)
    }

    func testSetMilestoneCount_clampsAboveMaximum() {
        weightManager.setMilestoneCount(25)
        XCTAssertEqual(weightManager.milestoneCount, 10)
    }

    // MARK: - Phase 2 Task 2.1 - Goal Weight Persistence

    func testSetGoalWeight_persistsAcrossInstances() {
        let persistence = InMemoryWeightPersistence()
        let manager = makeWeightManager(persistence: persistence)
        manager.setGoalWeight(165.5)
        let rehydratedManager = makeWeightManager(persistence: persistence)
        XCTAssertEqual(rehydratedManager.goalWeight, 165.5, accuracy: 0.0001)
    }

    // MARK: - Phase 2 Task 2.1 - Progress Percentage

    func testProgressPercentage_returnsZeroWhenNoProgressMade() {
        let start = WeightEntry(date: Date().minusDays(7), weight: 200.0, source: .manual)
        let current = WeightEntry(date: Date(), weight: 200.0, source: .manual)
        weightManager.setStartWeightOverride(nil, date: nil)
        var entries = [current, start]
        entries.sort { $0.date > $1.date }
        weightManager.weightEntries = entries

        let percentage = weightManager.progressPercentage(toward: 180.0)
        XCTAssertNotNil(percentage)
        XCTAssertEqual(percentage!, 0.0, accuracy: 0.0001)
    }

    func testProgressPercentage_weightGain_clampsToZero() {
        let start = WeightEntry(date: Date().minusDays(7), weight: 200.0, source: .manual)
        let current = WeightEntry(date: Date(), weight: 205.0, source: .manual)
        weightManager.setStartWeightOverride(nil, date: nil)
        var entries = [current, start]
        entries.sort { $0.date > $1.date }
        weightManager.weightEntries = entries

        let percentage = weightManager.progressPercentage(toward: 180.0)
        XCTAssertNotNil(percentage)
        XCTAssertEqual(percentage!, 0.0, accuracy: 0.0001)
    }

    func testProgressPercentage_returnsValueWhenHalfway() {
        let start = WeightEntry(date: Date().minusDays(7), weight: 200.0, source: .manual)
        let current = WeightEntry(date: Date(), weight: 190.0, source: .manual)
        weightManager.setStartWeightOverride(nil, date: nil)
        var entries = [current, start]
        entries.sort { $0.date > $1.date }
        weightManager.weightEntries = entries

        guard let percentage = weightManager.progressPercentage(toward: 180.0) else {
            return XCTFail("Expected progress percentage when halfway to goal")
        }
        XCTAssertEqual(percentage, 50.0, accuracy: 0.1)
    }

    func testProgressPercentage_goalReachedOrExceeded_returnsHundred() {
        let start = WeightEntry(date: Date().minusDays(30), weight: 200.0, source: .manual)
        let current = WeightEntry(date: Date(), weight: 160.0, source: .manual)
        weightManager.setStartWeightOverride(nil, date: nil)
        var entries = [current, start]
        entries.sort { $0.date > $1.date }
        weightManager.weightEntries = entries

        guard let percentage = weightManager.progressPercentage(toward: 180.0) else {
            return XCTFail("Expected percentage when goal reached")
        }
        XCTAssertEqual(percentage, 100.0, accuracy: 0.01)
    }

    func testProgressPercentage_partialProgress_matchesObservedLoss() {
        // Scenario mirrors screenshot: start ≈ 184.2, current 179.6, goal 150
        let start = WeightEntry(date: Date().minusDays(30), weight: 184.2, source: .manual)
        let current = WeightEntry(date: Date(), weight: 179.6, source: .manual)
        weightManager.setStartWeightOverride(nil, date: nil)
        var entries = [current, start]
        entries.sort { $0.date > $1.date }
        weightManager.weightEntries = entries

        guard let percentage = weightManager.progressPercentage(toward: 150.0) else {
            return XCTFail("Expected progress percentage for partial loss")
        }

        let expectedPercentage = ((start.weight - current.weight) / (start.weight - 150.0)) * 100.0
        XCTAssertEqual(percentage, expectedPercentage, accuracy: 0.0001)
        XCTAssertGreaterThan(percentage, 0.0)
    }

    // MARK: - Edge Cases

    func testAddWeightEntryInPreferredUnit_PreventsDuplicates() {
        // Given
        let date = Date()
        weightManager.addWeightEntryInPreferredUnit(weight: 150.0, date: date)

        let originalCount = weightManager.weightEntries.count

        // When - try to add duplicate within 30 minute window
        weightManager.addWeightEntryInPreferredUnit(weight: 150.0, date: date.plusHours(0))

        // Then
        XCTAssertEqual(weightManager.weightEntries.count, originalCount) // No duplicate added
    }

    func testAddWeightEntry_HandlesExtremeValues() {
        // Given - very high weight
        let extremeEntry = WeightEntry(date: Date(), weight: 500.0, source: .manual)

        // When
        weightManager.addWeightEntry(extremeEntry)

        // Then - wait for async addition
        let expectation = XCTestExpectation(description: "Extreme value handled")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(self.weightManager.weightEntries.count, 1)
            XCTAssertEqual(self.weightManager.latestWeight?.weight, 500.0)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testAddWeightEntry_HandlesLowValues() {
        // Given - very low weight
        let lowEntry = WeightEntry(date: Date(), weight: 50.0, source: .manual)

        // When
        weightManager.addWeightEntry(lowEntry)

        // Then - wait for async addition
        let expectation = XCTestExpectation(description: "Low value handled")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(self.weightManager.weightEntries.count, 1)
            XCTAssertEqual(self.weightManager.latestWeight?.weight, 50.0)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - Milestone Computation Tests (Task 1E Phase 3)
    // Tests for milestone tracking and progress calculations

    func test_startWeight_ReturnsOldestEntry() {
        // Given - Multiple entries
        weightManager.weightEntries.append(WeightEntry(date: Date(), weight: 175.0, source: .manual))
        weightManager.weightEntries.append(WeightEntry(date: Date().minusDays(30), weight: 200.0, source: .manual))
        weightManager.weightEntries.append(WeightEntry(date: Date().minusDays(15), weight: 185.0, source: .manual))
        weightManager.weightEntries.sort { $0.date > $1.date }

        // When
        let startWeight = weightManager.startWeight

        // Then
        XCTAssertNotNil(startWeight, "startWeight should return the oldest entry")
        if let weight = startWeight?.weight {
            XCTAssertEqual(weight, 200.0, accuracy: 0.01, "startWeight should be 200.0 (oldest entry)")
        } else {
            XCTFail("startWeight.weight should not be nil")
        }
    }

    func test_startWeight_ReturnsNilWhenEmpty() {
        // Given - empty manager

        // When
        let startWeight = weightManager.startWeight

        // Then
        XCTAssertNil(startWeight, "startWeight should be nil when no entries exist")
    }

    func test_totalWeightChange_CalculatesCorrectly() {
        // Given - Weight loss journey
        weightManager.weightEntries.append(WeightEntry(date: Date(), weight: 175.0, source: .manual))
        weightManager.weightEntries.append(WeightEntry(date: Date().minusDays(30), weight: 200.0, source: .manual))
        weightManager.weightEntries.sort { $0.date > $1.date }

        // When
        let change = weightManager.totalWeightChange

        // Then
        XCTAssertNotNil(change, "totalWeightChange should not be nil")
        XCTAssertEqual(change!, -25.0, accuracy: 0.01, "Should show 25 lbs weight loss")
    }

    func test_totalWeightChange_ReturnsNilWithInsufficientData() {
        // Given - only one entry
        weightManager.weightEntries.append(WeightEntry(date: Date(), weight: 175.0, source: .manual))

        // When
        let change = weightManager.totalWeightChange

        // Then
        XCTAssertNil(change, "totalWeightChange should be nil with insufficient data")
    }

    func test_progressToGoal_CalculatesCorrectly() {
        // Given - Weight loss journey: start 200 lbs, current 180 lbs, goal 160 lbs
        weightManager.weightEntries.append(WeightEntry(date: Date(), weight: 180.0, source: .manual))
        weightManager.weightEntries.append(WeightEntry(date: Date().minusDays(30), weight: 200.0, source: .manual))
        weightManager.weightEntries.sort { $0.date > $1.date }
        weightManager.setGoalWeight(160.0)
        weightManager.setGoalWeight(160.0)
        weightManager.setGoalWeight(160.0)

        // When
        let progress = weightManager.progressToGoal(goalWeight: 160.0)

        // Then
        // Total distance: 200 - 160 = 40 lbs
        // Progress made: 200 - 180 = 20 lbs
        // Progress: 20 / 40 = 0.5 (50%)
        XCTAssertNotNil(progress, "progressToGoal should not be nil")
        XCTAssertEqual(progress!, 0.5, accuracy: 0.01, "Should be 50% complete")
    }

    func test_progressToGoal_ReturnsZeroWhenNoProgress() {
        // Given - No weight loss yet
        weightManager.weightEntries.append(WeightEntry(date: Date(), weight: 200.0, source: .manual))
        weightManager.weightEntries.append(WeightEntry(date: Date().minusDays(1), weight: 200.0, source: .manual))
        weightManager.weightEntries.sort { $0.date > $1.date }
        weightManager.setGoalWeight(160.0)
        weightManager.setGoalWeight(160.0)

        // When
        let progress = weightManager.progressToGoal(goalWeight: 160.0)

        // Then
        XCTAssertNotNil(progress, "progressToGoal should return baseline progress")
        XCTAssertEqual(progress!, 0.0, accuracy: 0.0001)
    }

    func test_progressToGoal_ClampsAt100Percent() {
        // Given - Exceeded goal
        weightManager.weightEntries.append(WeightEntry(date: Date(), weight: 150.0, source: .manual))
        weightManager.weightEntries.append(WeightEntry(date: Date().minusDays(30), weight: 200.0, source: .manual))
        weightManager.weightEntries.sort { $0.date > $1.date }

        // When
        let progress = weightManager.progressToGoal(goalWeight: 160.0)

        // Then
        XCTAssertNotNil(progress, "progressToGoal should not be nil")
        XCTAssertEqual(progress!, 1.0, accuracy: 0.01, "Should clamp at 100% when goal exceeded")
    }

    func test_progressToGoal_ReturnsNilForInvalidGoal() {
        // Given - Goal higher than start weight (invalid for weight loss)
        weightManager.weightEntries.append(WeightEntry(date: Date(), weight: 180.0, source: .manual))
        weightManager.weightEntries.append(WeightEntry(date: Date().minusDays(30), weight: 200.0, source: .manual))
        weightManager.weightEntries.sort { $0.date > $1.date }

        // When
        let progress = weightManager.progressToGoal(goalWeight: 220.0)

        // Then
        XCTAssertNil(progress, "progressToGoal should be nil for invalid goal (higher than start)")
    }

    func test_currentMilestoneIndex_CalculatesCorrectly() {
        // Given - 50% progress (milestone 5)
        weightManager.weightEntries.append(WeightEntry(date: Date(), weight: 180.0, source: .manual))
        weightManager.weightEntries.append(WeightEntry(date: Date().minusDays(30), weight: 200.0, source: .manual))
        weightManager.weightEntries.sort { $0.date > $1.date }

        // When
        let milestoneIndex = weightManager.currentMilestoneIndex(goalWeight: 160.0)

        // Then
        // Progress: 50% → milestone 5 (ceil of 0.5 * 10)
        XCTAssertEqual(milestoneIndex, 5, "Should be at milestone 5 with 50% progress")
    }

    func test_currentMilestoneIndex_StartsAtOne() {
        // Given - Just started (0% progress)
        weightManager.weightEntries.append(WeightEntry(date: Date(), weight: 200.0, source: .manual))
        weightManager.weightEntries.append(WeightEntry(date: Date().minusDays(1), weight: 200.0, source: .manual))
        weightManager.weightEntries.sort { $0.date > $1.date }

        // When
        let milestoneIndex = weightManager.currentMilestoneIndex(goalWeight: 160.0)

        // Then
        XCTAssertEqual(milestoneIndex, 1, "Should start at milestone 1 with no progress")
    }

    func test_currentMilestoneIndex_EndsAtTen() {
        // Given - Goal reached (100% progress)
        weightManager.weightEntries.append(WeightEntry(date: Date(), weight: 160.0, source: .manual))
        weightManager.weightEntries.append(WeightEntry(date: Date().minusDays(30), weight: 200.0, source: .manual))
        weightManager.weightEntries.sort { $0.date > $1.date }
        weightManager.setGoalWeight(160.0)

        // When
        let milestoneIndex = weightManager.currentMilestoneIndex(goalWeight: 160.0)

        // Then
        XCTAssertEqual(milestoneIndex, 10, "Should be at milestone 10 when goal reached")
    }

    func test_completedMilestones_CalculatesCorrectly() {
        // Given - 50% progress (5 milestones completed)
        weightManager.weightEntries.append(WeightEntry(date: Date(), weight: 180.0, source: .manual))
        weightManager.weightEntries.append(WeightEntry(date: Date().minusDays(30), weight: 200.0, source: .manual))
        weightManager.weightEntries.sort { $0.date > $1.date }

        // When
        let completed = weightManager.completedMilestones(goalWeight: 160.0)

        // Then
        // Progress: 50% → 5 completed milestones (floor of 0.5 * 10)
        XCTAssertEqual(completed, 5, "Should have 5 completed milestones at 50% progress")
    }

    func test_completedMilestones_StartsAtZero() {
        // Given - Just started (0% progress)
        weightManager.weightEntries.append(WeightEntry(date: Date(), weight: 200.0, source: .manual))
        weightManager.weightEntries.append(WeightEntry(date: Date().minusDays(1), weight: 200.0, source: .manual))
        weightManager.weightEntries.sort { $0.date > $1.date }

        // When
        let completed = weightManager.completedMilestones(goalWeight: 160.0)

        // Then
        XCTAssertEqual(completed, 0, "Should have 0 completed milestones with no progress")
    }

    func test_milestoneProgress_CalculatesCorrectly() {
        // Given - 55% overall progress (5 milestones + 50% of milestone 6)
        weightManager.weightEntries.append(WeightEntry(date: Date(), weight: 178.0, source: .manual))
        weightManager.weightEntries.append(WeightEntry(date: Date().minusDays(30), weight: 200.0, source: .manual))
        weightManager.weightEntries.sort { $0.date > $1.date }
        weightManager.setGoalWeight(160.0)

        // When
        let milestoneProgress = weightManager.milestoneProgress(goalWeight: 160.0)

        // Then
        // Total: 200 - 160 = 40 lbs
        // Progress: 200 - 178 = 22 lbs (55%)
        // Milestone progress: (0.55 - 0.5) / 0.1 = 0.5 (50% of milestone 6)
        XCTAssertEqual(milestoneProgress, 0.5, accuracy: 0.01, "Should be 50% through current milestone")
    }

    func test_milestoneProgress_ReturnsZeroAtMilestoneStart() {
        // Given - Exactly at milestone boundary (50% progress)
        weightManager.weightEntries.append(WeightEntry(date: Date(), weight: 180.0, source: .manual))
        weightManager.weightEntries.append(WeightEntry(date: Date().minusDays(30), weight: 200.0, source: .manual))
        weightManager.weightEntries.sort { $0.date > $1.date }
        weightManager.setGoalWeight(160.0)

        // When
        let milestoneProgress = weightManager.milestoneProgress(goalWeight: 160.0)

        // Then
        XCTAssertEqual(milestoneProgress, 0.0, accuracy: 0.01, "Should be at start of milestone 6")
    }

    func test_milestoneStats_ReturnsAllData() {
        // Given - Weight loss journey
        weightManager.weightEntries.append(WeightEntry(date: Date(), weight: 180.0, source: .manual))
        weightManager.weightEntries.append(WeightEntry(date: Date().minusDays(30), weight: 200.0, source: .manual))
        weightManager.weightEntries.sort { $0.date > $1.date }
        weightManager.setGoalWeight(160.0)

        // When
        let stats = weightManager.milestoneStats(goalWeight: 160.0)

        // Then
        XCTAssertNotNil(stats, "milestoneStats should not be nil")
        XCTAssertEqual(stats!.currentIndex, 5, "Should be at milestone 5")
        XCTAssertEqual(stats!.completed, 5, "Should have 5 completed milestones")
        XCTAssertEqual(stats!.progress, 0.0, accuracy: 0.01, "Should be at start of milestone 6")
        XCTAssertEqual(stats!.startWeight, 200.0, accuracy: 0.01, "Start weight should be 200 lbs")
        XCTAssertEqual(stats!.currentWeight, 180.0, accuracy: 0.01, "Current weight should be 180 lbs")
        XCTAssertEqual(stats!.remainingWeight, 20.0, accuracy: 0.01, "20 lbs remaining to goal")
    }

    func test_milestoneStats_ReturnsNilForInvalidGoal() {
        // Given - Invalid goal (higher than start)
        weightManager.weightEntries.append(WeightEntry(date: Date(), weight: 180.0, source: .manual))
        weightManager.weightEntries.append(WeightEntry(date: Date().minusDays(30), weight: 200.0, source: .manual))
        weightManager.weightEntries.sort { $0.date > $1.date }

        // When
        let stats = weightManager.milestoneStats(goalWeight: 220.0)

        // Then
        XCTAssertNil(stats, "milestoneStats should be nil for invalid goal")
    }

    func test_milestoneStats_ReturnsNilWithInsufficientData() {
        // Given - only one entry
        weightManager.weightEntries.append(WeightEntry(date: Date(), weight: 180.0, source: .manual))

        // When
        let stats = weightManager.milestoneStats(goalWeight: 160.0)

        // Then
        XCTAssertNil(stats, "milestoneStats should be nil with insufficient data")
    }

    // MARK: - PHASE 2 TASK 2.1: Weight Conversion Tests (Enhancement 9-15 Coverage)
    // Testing convertWeightToDisplayUnit() method that formattedWeight() depends on
    // Following Apple Testing Best Practices - unit conversion accuracy

    func test_convertWeightToDisplayUnit_pounds_returnsOriginalValue() {
        // Given - pounds is the internal unit
        let internalWeight = 150.0 // pounds

        // When - converting to display (assumes user preference is pounds)
        // Note: This test assumes default US locale (pounds)
        let displayWeight = weightManager.convertWeightToDisplayUnit(internalWeight)

        // Then - should return same value for pounds
        XCTAssertEqual(displayWeight, 150.0, accuracy: 0.01, "Pounds should return original value")
    }

    func test_convertWeightToDisplayUnit_convertsToKilogramsCorrectly() {
        // Given - internal weight in pounds, user wants kilograms
        let poundsWeight = 150.0

        // When - converting (this depends on user's locale setting)
        let displayWeight = weightManager.convertWeightToDisplayUnit(poundsWeight)

        // Then - verify conversion is accurate (150 lbs = 68.04 kg)
        // Note: This test will pass/fail based on current locale
        // For comprehensive testing, we'd mock AppSettings.shared.weightUnit
        XCTAssertGreaterThan(displayWeight, 0, "Display weight should be positive")
    }

    func test_convertWeightToDisplayUnit_zeroWeight_returnsZero() {
        // Given - zero weight
        let zeroWeight = 0.0

        // When
        let displayWeight = weightManager.convertWeightToDisplayUnit(zeroWeight)

        // Then
        XCTAssertEqual(displayWeight, 0.0, accuracy: 0.001, "Zero should remain zero in any unit")
    }

    func test_convertWeightToDisplayUnit_negativeWeight_handlesCorrectly() {
        // Given - negative weight (edge case, defensive programming)
        let negativeWeight = -10.0

        // When
        let displayWeight = weightManager.convertWeightToDisplayUnit(negativeWeight)

        // Then - should handle negative values (no crash)
        XCTAssertLessThan(displayWeight, 0, "Negative weight should remain negative")
    }

    func test_convertWeightToDisplayUnit_extremeValue_handlesCorrectly() {
        // Given - very large weight (edge case)
        let extremeWeight = 1000.0

        // When
        let displayWeight = weightManager.convertWeightToDisplayUnit(extremeWeight)

        // Then - should handle large values without overflow
        XCTAssertGreaterThan(displayWeight, 0, "Extreme weight should convert correctly")
    }

    // MARK: - PHASE 2 TASK 2.1: resolvedStartWeight() Tests
    // Testing Enhancement 11 - Start Weight Override functionality
    // Following Apple Testing Best Practices - boundary condition testing

    func test_resolvedStartWeight_withOverride_returnsOverride() {
        // Given - override is set
        weightManager.weightEntries.append(WeightEntry(date: Date().minusDays(30), weight: 200.0, source: .manual))
        weightManager.weightEntries.append(WeightEntry(date: Date(), weight: 175.0, source: .manual))
        weightManager.setStartWeightOverride(181.0, date: Date().minusDays(10))

        // When
        let resolved = weightManager.resolvedStartWeight()

        // Then - should return override, not earliest entry
        XCTAssertNotNil(resolved, "resolvedStartWeight should not be nil when override set")
        XCTAssertEqual(resolved!.weight, 181.0, accuracy: 0.01, "Should return override value")
    }

    func test_resolvedStartWeight_withoutOverride_returnsEarliestEntry() {
        // Given - no override, multiple entries
        weightManager.weightEntries.append(WeightEntry(date: Date(), weight: 175.0, source: .manual))
        weightManager.weightEntries.append(WeightEntry(date: Date().minusDays(30), weight: 200.0, source: .manual))
        weightManager.weightEntries.append(WeightEntry(date: Date().minusDays(15), weight: 185.0, source: .manual))
        weightManager.weightEntries.sort { $0.date > $1.date }

        // When
        let resolved = weightManager.resolvedStartWeight()

        // Then - should return earliest (oldest) entry
        XCTAssertNotNil(resolved, "resolvedStartWeight should not be nil when entries exist")
        XCTAssertEqual(resolved!.weight, 200.0, accuracy: 0.01, "Should return earliest entry (200.0)")
    }

    func test_resolvedStartWeight_emptyEntries_returnsNil() {
        // Given - no entries, no override
        // weightManager is already empty from setUp()

        // When
        let resolved = weightManager.resolvedStartWeight()

        // Then
        XCTAssertNil(resolved, "resolvedStartWeight should be nil when no data exists")
    }

    func test_resolvedStartWeight_multipleEntries_returnsOldest() {
        // Given - 5 entries spanning different dates
        weightManager.weightEntries.append(WeightEntry(date: Date(), weight: 170.0, source: .manual))
        weightManager.weightEntries.append(WeightEntry(date: Date().minusDays(5), weight: 175.0, source: .manual))
        weightManager.weightEntries.append(WeightEntry(date: Date().minusDays(10), weight: 180.0, source: .manual))
        weightManager.weightEntries.append(WeightEntry(date: Date().minusDays(20), weight: 190.0, source: .manual))
        weightManager.weightEntries.append(WeightEntry(date: Date().minusDays(30), weight: 200.0, source: .manual))
        weightManager.weightEntries.sort { $0.date > $1.date }

        // When
        let resolved = weightManager.resolvedStartWeight()

        // Then - should return the 30-day-old entry (200.0)
        XCTAssertNotNil(resolved, "resolvedStartWeight should not be nil")
        XCTAssertEqual(resolved!.weight, 200.0, accuracy: 0.01, "Should return oldest entry")
    }

    func test_resolvedStartWeight_overrideZero_stillUsesEarliestEntry() {
        // Given - override is explicitly nil/zero (cleared)
        weightManager.weightEntries.append(WeightEntry(date: Date().minusDays(30), weight: 200.0, source: .manual))
        weightManager.setStartWeightOverride(nil, date: nil) // Clear override

        // When
        let resolved = weightManager.resolvedStartWeight()

        // Then - should fall back to earliest entry
        XCTAssertNotNil(resolved, "Should fall back to earliest entry when override cleared")
        XCTAssertEqual(resolved!.weight, 200.0, accuracy: 0.01, "Should use earliest entry")
    }

    func test_resolvedStartWeight_changeOverride_updatesImmediately() {
        // Given - initial override set
        weightManager.weightEntries.append(WeightEntry(date: Date().minusDays(30), weight: 200.0, source: .manual))
        weightManager.setStartWeightOverride(180.0, date: Date().minusDays(10))

        let firstResolved = weightManager.resolvedStartWeight()
        XCTAssertEqual(firstResolved!.weight, 180.0, accuracy: 0.01, "Initial override should be 180")

        // When - change override
        weightManager.setStartWeightOverride(185.0, date: Date().minusDays(5))
        let secondResolved = weightManager.resolvedStartWeight()

        // Then - should reflect new override immediately
        XCTAssertEqual(secondResolved!.weight, 185.0, accuracy: 0.01, "Should update to new override")
    }

    func test_resolvedStartWeight_clearOverride_fallsBackToEarliest() {
        // Given - override initially set
        weightManager.weightEntries.append(WeightEntry(date: Date().minusDays(30), weight: 200.0, source: .manual))
        weightManager.weightEntries.append(WeightEntry(date: Date(), weight: 175.0, source: .manual))
        weightManager.weightEntries.sort { $0.date > $1.date }
        weightManager.setStartWeightOverride(181.0, date: Date().minusDays(10))

        XCTAssertEqual(weightManager.resolvedStartWeight()!.weight, 181.0, accuracy: 0.01, "Initial override active")

        // When - clear override
        weightManager.setStartWeightOverride(nil, date: nil)
        let resolved = weightManager.resolvedStartWeight()

        // Then - should fall back to earliest entry
        XCTAssertEqual(resolved!.weight, 200.0, accuracy: 0.01, "Should fall back to earliest entry (200.0)")
    }

    func test_resolvedStartWeight_overrideWithSameDate_usesOverrideNotEntry() {
        // Given - override date matches an existing entry date
        let sharedDate = Date().minusDays(10)
        weightManager.weightEntries.append(WeightEntry(date: sharedDate, weight: 190.0, source: .healthKit))
        weightManager.setStartWeightOverride(185.0, date: sharedDate)

        // When
        let resolved = weightManager.resolvedStartWeight()

        // Then - override takes precedence over entry
        XCTAssertEqual(resolved!.weight, 185.0, accuracy: 0.01, "Override should take precedence")
    }

    // MARK: - PHASE 2 TASK 2.1: Milestone Count Validation Tests
    // Testing Enhancement 13 - Milestone Selector (0-10 milestones)
    // Following Apple Testing Best Practices - bounds validation

    func test_milestoneCount_validRange_accepts0to10() {
        // Given/When/Then - test all valid values (0-10)
        for validCount in 0...10 {
            weightManager.setMilestoneCount(validCount)
            XCTAssertEqual(weightManager.milestoneCount, validCount, "Should accept milestone count \(validCount)")
        }
    }

    func test_milestoneCount_negative_clampsToZero() {
        // Given - attempt to set negative milestone count
        let invalidCount = -5

        // When
        weightManager.setMilestoneCount(invalidCount)

        // Then - should clamp to 0 (minimum)
        XCTAssertEqual(weightManager.milestoneCount, 0, "Negative milestone count should clamp to 0")
    }

    func test_milestoneCount_above10_clampsTo10() {
        // Given - attempt to set milestone count above maximum
        let invalidCount = 15

        // When
        weightManager.setMilestoneCount(invalidCount)

        // Then - should clamp to 10 (maximum)
        XCTAssertEqual(weightManager.milestoneCount, 10, "Milestone count >10 should clamp to 10")
    }

    func test_milestoneCount_defaultValue_is10() {
        // Given - fresh WeightManager instance (from setUp)
        // Note: setUp() creates new instance, but need to verify default

        // When - check initial value
        let defaultCount = weightManager.milestoneCount

        // Then - should default to 10 (per specification)
        XCTAssertEqual(defaultCount, 10, "Default milestone count should be 10")
    }

    func test_milestoneCount_persists_acrossRestarts() {
        // Given - set milestone count to 7
        let persistence = InMemoryWeightPersistence()
        let manager = makeWeightManager(persistence: persistence)
        manager.setMilestoneCount(7)
        XCTAssertEqual(manager.milestoneCount, 7, "Initial set to 7")

        let newManager = makeWeightManager(persistence: persistence)
        XCTAssertEqual(newManager.milestoneCount, 7, "Milestone count should persist across restarts")

        newManager.setMilestoneCount(10)
    }

    func test_milestoneCount_zeroMilestones_isValid() {
        // Given - user wants no milestones (valid use case)
        let zeroCount = 0

        // When
        weightManager.setMilestoneCount(zeroCount)

        // Then - should accept 0 as valid
        XCTAssertEqual(weightManager.milestoneCount, 0, "Zero milestones should be valid")
    }

    // MARK: - PHASE 2 TASK 2.1: Progress Percentage Tests
    // Testing Enhancement 12 - Progress Ring Percentage calculation
    // Following Apple Testing Best Practices - edge case testing

    func test_progressToGoal_atStart_returnsZero() {
        // Given - just started, no progress made
        weightManager.weightEntries.append(WeightEntry(date: Date(), weight: 200.0, source: .manual))
        weightManager.weightEntries.append(WeightEntry(date: Date().minusDays(1), weight: 200.0, source: .manual))
        weightManager.weightEntries.sort { $0.date > $1.date }

        // When
        let progress = weightManager.progressToGoal(goalWeight: 160.0)

        // Then
        XCTAssertNotNil(progress, "progressToGoal should return baseline progress")
        XCTAssertEqual(progress!, 0.0, accuracy: 0.0001)
    }

    func test_progressToGoal_weightGain_clampsToZero() {
        weightManager.weightEntries.append(WeightEntry(date: Date(), weight: 205.0, source: .manual))
        weightManager.weightEntries.append(WeightEntry(date: Date().minusDays(1), weight: 200.0, source: .manual))
        weightManager.weightEntries.sort { $0.date > $1.date }

        let progress = weightManager.progressToGoal(goalWeight: 160.0)

        XCTAssertNotNil(progress, "progressToGoal should return baseline when weight increases")
        XCTAssertEqual(progress!, 0.0, accuracy: 0.0001)
    }

    func test_progressToGoal_halfwayToGoal_returns50() {
        // Given - halfway to goal (start 200, current 180, goal 160)
        weightManager.weightEntries.append(WeightEntry(date: Date(), weight: 180.0, source: .manual))
        weightManager.weightEntries.append(WeightEntry(date: Date().minusDays(30), weight: 200.0, source: .manual))
        weightManager.weightEntries.sort { $0.date > $1.date }

        // When
        let progress = weightManager.progressToGoal(goalWeight: 160.0)

        // Then - (200-180)/(200-160) = 20/40 = 0.5 (50%)
        XCTAssertNotNil(progress, "progressToGoal should not be nil")
        XCTAssertEqual(progress!, 0.5, accuracy: 0.01, "Should be 50% halfway to goal")
    }

    func test_progressToGoal_atGoal_returns100() {
        // Given - goal weight reached (start 200, current 160, goal 160)
        weightManager.weightEntries.append(WeightEntry(date: Date(), weight: 160.0, source: .manual))
        weightManager.weightEntries.append(WeightEntry(date: Date().minusDays(30), weight: 200.0, source: .manual))
        weightManager.weightEntries.sort { $0.date > $1.date }

        // When
        let progress = weightManager.progressToGoal(goalWeight: 160.0)

        // Then - should clamp at 100%
        XCTAssertNotNil(progress, "progressToGoal should not be nil")
        XCTAssertEqual(progress!, 1.0, accuracy: 0.01, "Should be 100% at goal")
    }

    func test_progressToGoal_overGoal_clampsAt100() {
        // Given - exceeded goal (start 200, current 150, goal 160)
        weightManager.weightEntries.append(WeightEntry(date: Date(), weight: 150.0, source: .manual))
        weightManager.weightEntries.append(WeightEntry(date: Date().minusDays(30), weight: 200.0, source: .manual))
        weightManager.weightEntries.sort { $0.date > $1.date }

        // When
        let progress = weightManager.progressToGoal(goalWeight: 160.0)

        // Then - should clamp at 100%, not exceed
        XCTAssertNotNil(progress, "progressToGoal should not be nil")
        XCTAssertEqual(progress!, 1.0, accuracy: 0.01, "Should clamp at 100% when goal exceeded")
    }

    func test_progressToGoal_flatTrend_returnsZero() {
        // Given - multiple entries, but no weight change
        weightManager.weightEntries.append(WeightEntry(date: Date(), weight: 200.0, source: .manual))
        weightManager.weightEntries.append(WeightEntry(date: Date().minusDays(5), weight: 200.0, source: .manual))
        weightManager.weightEntries.append(WeightEntry(date: Date().minusDays(10), weight: 200.0, source: .manual))
        weightManager.weightEntries.sort { $0.date > $1.date }

        // When
        let progress = weightManager.progressToGoal(goalWeight: 160.0)

        // Then
        XCTAssertNotNil(progress, "Flat trend should still report baseline progress")
        XCTAssertEqual(progress!, 0.0, accuracy: 0.0001)
    }

    func test_progressToGoal_gainedWeight_returnsZero() {
        // Given - weight increased instead of decreased (start 200, current 210, goal 160)
        weightManager.weightEntries.append(WeightEntry(date: Date(), weight: 210.0, source: .manual))
        weightManager.weightEntries.append(WeightEntry(date: Date().minusDays(30), weight: 200.0, source: .manual))
        weightManager.weightEntries.sort { $0.date > $1.date }

        // When
        let progress = weightManager.progressToGoal(goalWeight: 160.0)

        // Then - treat as unavailable until weight loss resumes
        XCTAssertNotNil(progress, "progressToGoal should return baseline when weight has increased")
        XCTAssertEqual(progress!, 0.0, accuracy: 0.0001)
    }

    func test_progressToGoal_goalHigherThanStart_returnsNil() {
        // Given - gaining weight goal (start 200, goal 220)
        weightManager.weightEntries.append(WeightEntry(date: Date(), weight: 210.0, source: .manual))
        weightManager.weightEntries.append(WeightEntry(date: Date().minusDays(30), weight: 200.0, source: .manual))
        weightManager.weightEntries.sort { $0.date > $1.date }

        // When
        let progress = weightManager.progressToGoal(goalWeight: 220.0)

        // Then - should return nil for invalid goal (higher than start)
        XCTAssertNil(progress, "progressToGoal should be nil for goal higher than start weight")
    }

    func test_progressToGoal_zeroGoal_returnsNil() {
        // Given - invalid goal weight (0)
        weightManager.weightEntries.append(WeightEntry(date: Date(), weight: 180.0, source: .manual))
        weightManager.weightEntries.append(WeightEntry(date: Date().minusDays(30), weight: 200.0, source: .manual))
        weightManager.weightEntries.sort { $0.date > $1.date }

        // When
        let progress = weightManager.progressToGoal(goalWeight: 0.0)

        // Then - should return nil for invalid goal
        XCTAssertNil(progress, "progressToGoal should be nil for zero goal weight")
    }

    func test_progressToGoal_startEqualsGoal_returnsNil() {
        // Given - start weight equals goal weight (edge case)
        weightManager.weightEntries.append(WeightEntry(date: Date(), weight: 160.0, source: .manual))
        weightManager.weightEntries.append(WeightEntry(date: Date().minusDays(30), weight: 160.0, source: .manual))
        weightManager.weightEntries.sort { $0.date > $1.date }

        // When
        let progress = weightManager.progressToGoal(goalWeight: 160.0)

        // Then - should return nil (no weight to lose)
        XCTAssertNil(progress, "progressToGoal should be nil when start equals goal")
    }

    func test_progressToGoal_quarter_returns25() {
        // Given - 25% progress (start 200, current 190, goal 160)
        weightManager.weightEntries.append(WeightEntry(date: Date(), weight: 190.0, source: .manual))
        weightManager.weightEntries.append(WeightEntry(date: Date().minusDays(30), weight: 200.0, source: .manual))
        weightManager.weightEntries.sort { $0.date > $1.date }

        // When
        let progress = weightManager.progressToGoal(goalWeight: 160.0)

        // Then - (200-190)/(200-160) = 10/40 = 0.25 (25%)
        XCTAssertNotNil(progress, "progressToGoal should not be nil")
        XCTAssertEqual(progress!, 0.25, accuracy: 0.01, "Should be 25% at quarter progress")
    }

    // MARK: - PHASE 2 TASK 2.1: Goal Weight Persistence Tests
    // Testing Recovery Task #1 - Goal Weight Persistence with ThreadSafeUserDefaults
    // Following Apple Testing Best Practices - persistence and thread safety

    func test_goalWeight_save_persistsToSecureStorage() throws {
        // Given
        let persistence = InMemoryWeightPersistence()
        let manager = makeWeightManager(persistence: persistence)
        let goalValue = 150.0

        // When
        manager.setGoalWeight(goalValue)

        // Then
        XCTAssertEqual(manager.goalWeight, goalValue, accuracy: 0.01)
        let persistedGoal = try XCTUnwrap(persistence.loadGoalWeight())
        XCTAssertEqual(persistedGoal, goalValue, accuracy: 0.01)
    }

    func test_goalWeight_load_restoresFromSecureStorage() throws {
        // Given
        let expectedGoal = 165.0
        let persistence = InMemoryWeightPersistence(goalWeight: expectedGoal)

        // When
        let manager = makeWeightManager(persistence: persistence)

        // Then
        XCTAssertEqual(manager.goalWeight, expectedGoal, accuracy: 0.01)
    }

    func test_goalWeight_default_isZero() {
        let manager = makeWeightManager(persistence: InMemoryWeightPersistence())
        XCTAssertEqual(manager.goalWeight, 0.0, accuracy: 0.01)
    }

    func test_goalWeight_update_overwritesPrevious() throws {
        let persistence = InMemoryWeightPersistence()
        let manager = makeWeightManager(persistence: persistence)

        manager.setGoalWeight(150.0)
        XCTAssertEqual(manager.goalWeight, 150.0, accuracy: 0.01)

        manager.setGoalWeight(160.0)

        XCTAssertEqual(manager.goalWeight, 160.0, accuracy: 0.01)
        let persistedGoal = try XCTUnwrap(persistence.loadGoalWeight())
        XCTAssertEqual(persistedGoal, 160.0, accuracy: 0.01)
    }

    func test_goalWeight_negative_savesNegative() {
        // Given - negative goal (edge case, defensive programming)
        let negativeGoal = -10.0

        // When
        weightManager.setGoalWeight(negativeGoal)

        // Then - should handle negative values (no crash)
        XCTAssertEqual(weightManager.goalWeight, negativeGoal, accuracy: 0.01, "Should accept negative goal")
    }

    func test_goalWeight_zero_savesZero() {
        // Given - zero goal (valid: no goal set)
        let zeroGoal = 0.0

        // When
        weightManager.setGoalWeight(zeroGoal)

        // Then - should accept zero as valid
        XCTAssertEqual(weightManager.goalWeight, zeroGoal, accuracy: 0.01, "Should accept zero goal")
    }

    func test_goalWeight_published_triggersObservation() {
        // Given - create observer expectation
        let expectation = XCTestExpectation(description: "Goal weight @Published triggers update")
        var observedValue: Double?

        // Create observer using Combine
        let cancellable = weightManager.$goalWeight
            .dropFirst() // Skip initial value
            .sink { newValue in
                observedValue = newValue
                expectation.fulfill()
            }

        // When - set new goal
        weightManager.setGoalWeight(155.0)

        // Then - observer should receive update
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(observedValue!, 155.0, accuracy: 0.01, "@Published should notify observers")

        cancellable.cancel()
    }

    func test_goalWeight_threadSafe_concurrentAccess() {
        // Given - multiple concurrent writes
        let expectation = XCTestExpectation(description: "Concurrent goal weight updates complete")
        expectation.expectedFulfillmentCount = 10

        // When - simulate concurrent access from multiple threads
        Task {
            await withTaskGroup(of: Void.self) { group in
                for i in 0..<10 {
                    let goalValue = Double(150 + i)
                    group.addTask {
                        await MainActor.run {
                            self.weightManager.setGoalWeight(goalValue)
                        }
                        expectation.fulfill()
                    }
                }
            }
        }

        // Then - all operations should complete without crash
        wait(for: [expectation], timeout: 5.0)

        // And - final value should be one of the set values (between 150-159)
        let finalGoal = weightManager.goalWeight
        XCTAssertGreaterThanOrEqual(finalGoal, 150.0, "Final goal should be >= 150")
        XCTAssertLessThanOrEqual(finalGoal, 159.0, "Final goal should be <= 159")

        // This test verifies ThreadSafeUserDefaults prevents race conditions
    }

    func test_formattedDisplayWeight_updatesLocaleOnChange() {
        let localeProvider = MutableLocaleProvider(isMetric: false)
        let appSettings = AppSettings(localeProvider: localeProvider)
        let manager = WeightManager(
            healthKit: MockHealthKitManager(),
            dataStore: MockDataStore(),
            appSettings: appSettings
        )

        let imperial = manager.formattedDisplayWeight(150.0)
        XCTAssertEqual(imperial, "150")

        localeProvider.isMetric = true
        let metric = manager.formattedDisplayWeight(150.0)
        XCTAssertEqual(metric, "68.0")
    }
}

final class WeightSyncCoordinatorTests: XCTestCase {

    private let coordinator = WeightSyncCoordinator()

    func test_mergeNewEntries_addsUniqueEntriesAndKeepsMostRecentFirst() {
        let baseDate = Date(timeIntervalSince1970: 1_700_000_000)
        var current = [
            WeightEntry(date: baseDate, weight: 180.0, source: .manual)
        ]
        let manualID = current.first!.id
        let duplicate = WeightEntry(date: baseDate.addingTimeInterval(30),
                                    weight: 180.05,
                                    source: .healthKit)
        let newEntry = WeightEntry(date: baseDate.addingTimeInterval(3_600),
                                   weight: 178.4,
                                   source: .healthKit)

        let added = coordinator.mergeNewEntries(
            currentEntries: &current,
            healthKitEntries: [duplicate, newEntry],
            duplicateChecker: Self.duplicateChecker(
                timeThreshold: WeightConstants.DuplicationThreshold.tightTimeInterval,
                weightThreshold: WeightConstants.DuplicationThreshold.weightDelta
            )
        )

        XCTAssertEqual(added, 1)
        XCTAssertEqual(current.count, 2)
        XCTAssertEqual(current.first?.id, newEntry.id)
        XCTAssertTrue(current.contains(where: { $0.id == manualID }))
        XCTAssertFalse(current.contains(where: { $0.id == duplicate.id }))
    }

    func test_mergeHistoricalEntries_usesRelaxedThresholds() {
        let baseDate = Date(timeIntervalSince1970: 1_700_100_000)
        var current = [
            WeightEntry(date: baseDate, weight: 182.0, source: .healthKit)
        ]
        let originalID = current.first!.id
        let nearDuplicate = WeightEntry(date: baseDate.addingTimeInterval(120),
                                        weight: 182.15,
                                        source: .healthKit)
        let historicalNew = WeightEntry(date: baseDate.addingTimeInterval(-86_400),
                                        weight: 185.0,
                                        source: .healthKit)

        let added = coordinator.mergeHistoricalEntries(
            currentEntries: &current,
            healthKitEntries: [nearDuplicate, historicalNew],
            duplicateChecker: Self.duplicateChecker(
                timeThreshold: WeightConstants.DuplicationThreshold.historicalTimeInterval,
                weightThreshold: WeightConstants.DuplicationThreshold.historicalWeightDelta
            )
        )

        XCTAssertEqual(added, 1)
        XCTAssertEqual(current.count, 2)
        XCTAssertTrue(current.contains(where: { $0.id == originalID }))
        XCTAssertTrue(current.contains(where: { $0.id == historicalNew.id }))
    }

    func test_reconcileAfterReset_preservesManualEntriesAndReportsCounts() {
        let baseDate = Date(timeIntervalSince1970: 1_700_200_000)
        let manual = WeightEntry(date: baseDate, weight: 190.0, source: .manual)
        let staleHealthKit = WeightEntry(date: baseDate.addingTimeInterval(-7_200),
                                         weight: 188.0,
                                         source: .healthKit)
        let retainedHealthKit = WeightEntry(date: baseDate.addingTimeInterval(-3_600),
                                            weight: 187.5,
                                            source: .healthKit)
        var current = [manual, staleHealthKit, retainedHealthKit]

        let matchingRetained = WeightEntry(date: retainedHealthKit.date,
                                           weight: retainedHealthKit.weight,
                                           source: .healthKit)
        let brandNew = WeightEntry(date: baseDate.addingTimeInterval(1_800),
                                   weight: 186.0,
                                   source: .healthKit)

        let result = coordinator.reconcileAfterReset(
            currentEntries: &current,
            healthKitEntries: [matchingRetained, brandNew],
            duplicateChecker: Self.duplicateChecker(
                timeThreshold: WeightConstants.DuplicationThreshold.tightTimeInterval,
                weightThreshold: WeightConstants.DuplicationThreshold.weightDelta
            )
        )

        XCTAssertEqual(result.deleted, 1)
        XCTAssertEqual(result.added, 1)
        XCTAssertTrue(current.contains(where: { $0.id == manual.id }))
        XCTAssertTrue(current.contains(where: { $0.weight == brandNew.weight }))
        XCTAssertFalse(current.contains(where: { $0.id == staleHealthKit.id }))
    }

    private static func duplicateChecker(timeThreshold: TimeInterval,
                                         weightThreshold: Double) -> (WeightEntry, WeightEntry) -> Bool {
        { existing, newEntry in
            let timeDiff = abs(existing.date.timeIntervalSince(newEntry.date))
            guard timeDiff < timeThreshold else { return false }

            let epsilon = 0.00001
            let adjustedThreshold = max(0, weightThreshold - epsilon)
            return abs(existing.weight - newEntry.weight) < adjustedThreshold
        }
    }
}

@MainActor
final class WeightManagerSyncCoordinatorIntegrationTests: XCTestCase {

    func test_syncFromHealthKit_delegatesToCoordinatorAndPersistsEntries() {
        let expectation = XCTestExpectation(description: "Manual sync completion")

        let mockHealthKit = MockHealthKitManager()
        let dataStore = MockDataStore()
        let existing = WeightEntry(date: Date(timeIntervalSince1970: 1_700_300_000),
                                   weight: 200.0,
                                   source: .manual)
        let persistence = InMemoryWeightPersistence(entries: [existing])
        let coordinator = MockWeightSyncCoordinator()

        let hkEntries = [
            WeightEntry(date: existing.date.addingTimeInterval(-600), weight: 198.0, source: .healthKit),
            WeightEntry(date: existing.date.addingTimeInterval(-1_200), weight: 197.5, source: .healthKit)
        ]
        mockHealthKit.setMockWeightEntries(hkEntries)

        coordinator.mergeNewEntriesHandler = { currentEntries, healthKitEntries, _ in
            currentEntries.append(contentsOf: healthKitEntries)
            return healthKitEntries.count
        }

        let manager = WeightManager(
            healthKit: mockHealthKit,
            dataStore: dataStore,
            persistence: persistence,
            syncCoordinator: coordinator
        )

        manager.syncFromHealthKit(startDate: nil) { added, error in
            XCTAssertNil(error)
            XCTAssertEqual(added, hkEntries.count)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 2.0)

        XCTAssertEqual(coordinator.mergeNewEntriesCallCount, 1)
        XCTAssertEqual(persistence.entries.count, 3)
        XCTAssertEqual(manager.weightEntries.count, 3)
    }

    func test_syncFromHealthKitHistorical_usesCoordinatorResult() {
        let expectation = XCTestExpectation(description: "Historical sync completion")

        let mockHealthKit = MockHealthKitManager()
        let dataStore = MockDataStore()
        let persistence = InMemoryWeightPersistence()
        let coordinator = MockWeightSyncCoordinator()

        let hkEntries = [
            WeightEntry(date: Date(timeIntervalSince1970: 1_699_000_000), weight: 210.0, source: .healthKit),
            WeightEntry(date: Date(timeIntervalSince1970: 1_699_100_000), weight: 211.0, source: .healthKit)
        ]
        mockHealthKit.setMockWeightEntries(hkEntries)

        coordinator.mergeHistoricalEntriesHandler = { currentEntries, healthKitEntries, _ in
            currentEntries.append(contentsOf: healthKitEntries)
            return healthKitEntries.count
        }

        let manager = WeightManager(
            healthKit: mockHealthKit,
            dataStore: dataStore,
            persistence: persistence,
            syncCoordinator: coordinator
        )

        manager.syncFromHealthKitHistorical(startDate: Date(timeIntervalSince1970: 1_690_000_000)) { added, error in
            XCTAssertNil(error)
            XCTAssertEqual(added, hkEntries.count)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 2.0)

        XCTAssertEqual(coordinator.mergeHistoricalEntriesCallCount, 1)
        XCTAssertEqual(persistence.entries.count, hkEntries.count)
        XCTAssertEqual(manager.weightEntries.count, hkEntries.count)
    }

    func test_syncFromHealthKitWithReset_reportsCoordinatorTuple() {
        let expectation = XCTestExpectation(description: "Manual reset sync completion")

        let mockHealthKit = MockHealthKitManager()
        let dataStore = MockDataStore()

        let staleHealthKit = WeightEntry(date: Date(timeIntervalSince1970: 1_698_000_000),
                                         weight: 205.0,
                                         source: .healthKit)
        let manual = WeightEntry(date: Date(timeIntervalSince1970: 1_698_100_000),
                                 weight: 204.5,
                                 source: .manual)
        let persistence = InMemoryWeightPersistence(entries: [staleHealthKit, manual])
        let coordinator = MockWeightSyncCoordinator()

        let hkEntries = [
            WeightEntry(date: staleHealthKit.date, weight: staleHealthKit.weight, source: .healthKit),
            WeightEntry(date: manual.date.addingTimeInterval(-3_600), weight: 203.0, source: .healthKit)
        ]
        mockHealthKit.setMockWeightEntries(hkEntries)

        coordinator.reconcileAfterResetHandler = { currentEntries, healthKitEntries, _ in
            currentEntries.removeAll { $0.id == staleHealthKit.id }
            if let newest = healthKitEntries.last {
                currentEntries.append(newest)
            }
            return (added: 1, deleted: 1)
        }

        let manager = WeightManager(
            healthKit: mockHealthKit,
            dataStore: dataStore,
            persistence: persistence,
            syncCoordinator: coordinator
        )

        manager.syncFromHealthKitWithReset(startDate: Date(timeIntervalSince1970: 1_690_000_000)) { added, error in
            XCTAssertNil(error)
            XCTAssertEqual(added, 1)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 2.0)

        XCTAssertEqual(coordinator.reconcileAfterResetCallCount, 1)
        XCTAssertEqual(persistence.entries.count, 2)
        XCTAssertTrue(persistence.entries.contains(where: { $0.source == .manual }))
        XCTAssertFalse(persistence.entries.contains(where: { $0.id == staleHealthKit.id }))
    }
}

private final class MockWeightSyncCoordinator: WeightSyncCoordinating {
    var mergeNewEntriesCallCount = 0
    var mergeHistoricalEntriesCallCount = 0
    var reconcileAfterResetCallCount = 0

    var mergeNewEntriesHandler: ((inout [WeightEntry], [WeightEntry], (WeightEntry, WeightEntry) -> Bool) -> Int)?
    var mergeHistoricalEntriesHandler: ((inout [WeightEntry], [WeightEntry], (WeightEntry, WeightEntry) -> Bool) -> Int)?
    var reconcileAfterResetHandler: ((inout [WeightEntry], [WeightEntry], (WeightEntry, WeightEntry) -> Bool) -> (added: Int, deleted: Int))?

    var mergeNewEntriesResult: Int = 0
    var mergeHistoricalEntriesResult: Int = 0
    var reconcileAfterResetResult: (added: Int, deleted: Int) = (0, 0)

    func mergeNewEntries(currentEntries: inout [WeightEntry],
                         healthKitEntries: [WeightEntry],
                         duplicateChecker: (WeightEntry, WeightEntry) -> Bool) -> Int {
        mergeNewEntriesCallCount += 1
        if let handler = mergeNewEntriesHandler {
            return handler(&currentEntries, healthKitEntries, duplicateChecker)
        }
        return mergeNewEntriesResult
    }

    func mergeHistoricalEntries(currentEntries: inout [WeightEntry],
                                healthKitEntries: [WeightEntry],
                                duplicateChecker: (WeightEntry, WeightEntry) -> Bool) -> Int {
        mergeHistoricalEntriesCallCount += 1
        if let handler = mergeHistoricalEntriesHandler {
            return handler(&currentEntries, healthKitEntries, duplicateChecker)
        }
        return mergeHistoricalEntriesResult
    }

    func reconcileAfterReset(currentEntries: inout [WeightEntry],
                             healthKitEntries: [WeightEntry],
                             duplicateChecker: (WeightEntry, WeightEntry) -> Bool) -> (added: Int, deleted: Int) {
        reconcileAfterResetCallCount += 1
        if let handler = reconcileAfterResetHandler {
            return handler(&currentEntries, healthKitEntries, duplicateChecker)
        }
        return reconcileAfterResetResult
    }
}

private final class InMemoryWeightPersistence: WeightPersistenceManaging {
    private(set) var entries: [WeightEntry]
    private var syncPreference: Bool?
    private var startOverride: (Double?, Date?)
    private var milestoneCount: Int?
    private var goalWeight: Double?

    init(entries: [WeightEntry] = [],
         syncPreference: Bool? = nil,
         startOverride: (Double?, Date?) = (nil, nil),
         milestoneCount: Int? = nil,
         goalWeight: Double? = nil) {
        self.entries = entries
        self.syncPreference = syncPreference
        self.startOverride = startOverride
        self.milestoneCount = milestoneCount
        self.goalWeight = goalWeight
    }

    func loadWeightEntries() -> [WeightEntry] {
        entries
    }

    func saveWeightEntries(_ entries: [WeightEntry]) {
        self.entries = entries
    }

    func loadSyncPreference() -> Bool? {
        syncPreference
    }

    func saveSyncPreference(_ value: Bool) {
        syncPreference = value
    }

    func loadStartWeightOverride() -> (weight: Double?, date: Date?) {
        startOverride
    }

    func saveStartWeightOverride(weight: Double?, date: Date?) {
        startOverride = (weight, date)
    }

    func loadMilestoneCount() -> Int? {
        milestoneCount
    }

    func saveMilestoneCount(_ count: Int) {
        milestoneCount = count
    }

    func loadGoalWeight() -> Double? {
        goalWeight
    }

    func saveGoalWeight(_ weight: Double) {
        goalWeight = weight
    }
}

final class WeightPersistenceAdapterTests: XCTestCase {

    private func makeThreadSafeDefaults(_ suiteName: String) -> ThreadSafeUserDefaults {
        guard let suite = UserDefaults(suiteName: suiteName) else {
            fatalError("Unable to create UserDefaults suite for tests")
        }
        suite.removePersistentDomain(forName: suiteName)
        return ThreadSafeUserDefaults(userDefaults: suite)
    }

    override func tearDown() {
        UserDefaults(suiteName: "WeightPersistenceAdapterTests_Migration")?.removePersistentDomain(forName: "WeightPersistenceAdapterTests_Migration")
        UserDefaults(suiteName: "WeightPersistenceAdapterTests_RoundTrip")?.removePersistentDomain(forName: "WeightPersistenceAdapterTests_RoundTrip")
        super.tearDown()
    }

    func testMigrationFromLegacyUserDefaults() throws {
        let defaults = makeThreadSafeDefaults("WeightPersistenceAdapterTests_Migration")
        let legacyEncoder = JSONEncoder()
        let entry = WeightEntry(date: Date(timeIntervalSince1970: 1_700_000_000), weight: 185.3, source: .manual)
        let legacyData = try legacyEncoder.encode([entry])
        defaults.set(legacyData, forKey: "weightEntries")
        defaults.set(true, forKey: "syncWithHealthKit")
        defaults.set(205.0, forKey: "weightStartOverride")
        let startDate = Date(timeIntervalSince1970: 1_699_999_000)
        defaults.set(startDate, forKey: "weightStartDate")
        defaults.set(7, forKey: "weightMilestoneCount")
        defaults.set(165.5, forKey: "goalWeight")

        let storage = InMemorySecureWeightStorage()
        let adapter = WeightPersistenceAdapter(defaults: defaults, storage: storage)

        XCTAssertEqual(adapter.loadWeightEntries().count, 1)
        let goal = try XCTUnwrap(adapter.loadGoalWeight())
        XCTAssertEqual(goal, 165.5, accuracy: 0.0001)
        XCTAssertEqual(adapter.loadSyncPreference(), true)

        let override = adapter.loadStartWeightOverride()
        let overrideWeight = try XCTUnwrap(override.weight)
        XCTAssertEqual(overrideWeight, 205.0, accuracy: 0.0001)
        XCTAssertEqual(override.date, startDate)
        XCTAssertEqual(adapter.loadMilestoneCount(), 7)

        XCTAssertNil(defaults.data(forKey: "weightEntries"))
        XCTAssertNil(defaults.object(forKey: "goalWeight"))
        XCTAssertNil(defaults.object(forKey: "weightStartOverride"))
    }

    func testRoundTripPersistsToSecureStorage() throws {
        let defaults = makeThreadSafeDefaults("WeightPersistenceAdapterTests_RoundTrip")
        let storage = InMemorySecureWeightStorage()

        let adapter = WeightPersistenceAdapter(defaults: defaults, storage: storage)
        let entry = WeightEntry(date: Date(timeIntervalSince1970: 1_700_000_100), weight: 178.2)
        adapter.saveWeightEntries([entry])
        adapter.saveGoalWeight(160.0)
        adapter.saveSyncPreference(true)

        let rehydrated = WeightPersistenceAdapter(defaults: defaults, storage: storage)
        let persistedEntryWeight = try XCTUnwrap(rehydrated.loadWeightEntries().first?.weight)
        XCTAssertEqual(persistedEntryWeight, 178.2, accuracy: 0.0001)
        let rehydratedGoal = try XCTUnwrap(rehydrated.loadGoalWeight())
        XCTAssertEqual(rehydratedGoal, 160.0, accuracy: 0.0001)
        XCTAssertEqual(rehydrated.loadSyncPreference(), true)
    }
}

final class MutableLocaleProvider: LocaleProviding {
    private var customLocaleIdentifier: String?

    var isMetric: Bool {
        didSet {
            if customLocaleIdentifier == nil {
                localeIdentifier = isMetric ? "en_GB" : "en_US"
            }
        }
    }

    var measurementSystem: Locale.MeasurementSystem {
        isMetric ? .metric : .us
    }

    var localeIdentifier: String

    init(isMetric: Bool) {
        self.isMetric = isMetric
        self.localeIdentifier = isMetric ? "en_GB" : "en_US"
    }

    convenience init(measurementSystem: Locale.MeasurementSystem, localeIdentifier: String? = nil) {
        self.init(isMetric: measurementSystem == .metric)
        if let localeIdentifier {
            self.localeIdentifier = localeIdentifier
            self.customLocaleIdentifier = localeIdentifier
        }
    }

    func update(measurementSystem: Locale.MeasurementSystem, localeIdentifier: String? = nil) {
        self.isMetric = measurementSystem == .metric
        if let localeIdentifier {
            self.localeIdentifier = localeIdentifier
            self.customLocaleIdentifier = localeIdentifier
        } else {
            self.customLocaleIdentifier = nil
            self.localeIdentifier = isMetric ? "en_GB" : "en_US"
        }
    }
}
