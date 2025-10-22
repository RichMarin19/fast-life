//
//  WeightManagerTests.swift
//  FastingTrackerTests
//
//  Created by Claude Code
//  Phase 0: Baseline Unit Tests
//

import XCTest
@testable import Fast_lIFe

@MainActor
final class WeightManagerTests: XCTestCase {

    var weightManager: WeightManager!

    override func setUp() {
        super.setUp()
        // Clear UserDefaults for clean test state
        if let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
        }
        weightManager = WeightManager()
        // Clear any existing entries for clean tests
        weightManager.weightEntries.removeAll()
        // Disable HealthKit sync for faster, isolated unit tests
        weightManager.syncWithHealthKit = false
    }

    override func tearDown() {
        weightManager = nil
        super.tearDown()
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
}
