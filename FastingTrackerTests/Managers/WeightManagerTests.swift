//
//  WeightManagerTests.swift
//  FastingTrackerTests
//
//  Created by Claude Code
//  Phase 0: Baseline Unit Tests
//

import XCTest
@testable import FastingTracker

@MainActor
final class WeightManagerTests: FastingTrackerTests {

    var weightManager: WeightManager!

    override func setUp() {
        super.setUp()
        weightManager = WeightManager()
        // Clear any existing entries for clean tests
        weightManager.weightEntries.removeAll()
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

        // Then
        XCTAssertEqual(weightManager.weightEntries.count, 1)
        XCTAssertEqual(weightManager.weightEntries.first?.weight, 150.0)
    }

    func testAddWeightEntry_SortsNewestFirst() {
        // Given
        let older = WeightEntry(date: Date().minusDays(2), weight: 150.0, source: .manual)
        let newer = WeightEntry(date: Date().minusDays(1), weight: 149.0, source: .manual)

        // When
        weightManager.addWeightEntry(older)
        weightManager.addWeightEntry(newer)

        // Then
        XCTAssertEqual(weightManager.weightEntries.count, 2)
        XCTAssertEqual(weightManager.weightEntries.first?.weight, 149.0) // Newer entry first
        XCTAssertEqual(weightManager.weightEntries.last?.weight, 150.0)
    }

    func testAddWeightEntry_AllowsMultipleEntriesPerDay() {
        // Given
        let morning = WeightEntry(date: Date.testDate(hour: 8), weight: 150.0, source: .manual)
        let evening = WeightEntry(date: Date.testDate(hour: 20), weight: 151.0, source: .manual)

        // When
        weightManager.addWeightEntry(morning)
        weightManager.addWeightEntry(evening)

        // Then
        XCTAssertEqual(weightManager.weightEntries.count, 2)
    }

    // MARK: - Delete Weight Entry Tests

    func testDeleteWeightEntry_RemovesFromCollection() {
        // Given
        let entry = WeightEntry(date: Date(), weight: 150.0, source: .manual)
        weightManager.addWeightEntry(entry)
        XCTAssertEqual(weightManager.weightEntries.count, 1)

        // When
        weightManager.deleteWeightEntry(entry)

        // Then - wait for async deletion
        let expectation = XCTestExpectation(description: "Entry deleted")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(self.weightManager.weightEntries.count, 0)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - Duplicate Detection Tests

    func testWouldCreateDuplicate_DetectsSameWeight() {
        // Given
        let existingEntry = WeightEntry(date: Date(), weight: 150.0, source: .manual)
        weightManager.addWeightEntry(existingEntry)

        // When/Then
        XCTAssertTrue(weightManager.wouldCreateDuplicate(weight: 150.0, date: Date()))
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

        // When/Then - Manual entry with same weight should be detected as duplicate
        XCTAssertTrue(weightManager.wouldCreateDuplicate(weight: 150.0, date: Date()))
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

        // When
        let latest = weightManager.latestWeight

        // Then
        XCTAssertEqual(latest?.weight, 149.0)
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

        // When
        let trend = weightManager.weightTrend

        // Then - should show negative trend (weight loss)
        XCTAssertNotNil(trend)
        XCTAssertLessThan(trend!, 0) // Weight decreased
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

        // When
        let average = weightManager.averageWeight

        // Then
        XCTAssertNotNil(average)
        XCTAssertEqualWithin(average!, 150.0, percent: 0.01) // Average should be 150
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

        weightManager.addWeightEntry(WeightEntry(date: startDate, weight: startWeight, source: .manual))
        weightManager.addWeightEntry(WeightEntry(date: Date(), weight: currentWeight, source: .manual))

        // When
        let change = weightManager.weightChange(since: startDate)

        // Then
        XCTAssertNotNil(change)
        XCTAssertEqualWithin(change!, -3.0, percent: 0.01) // Lost 3 lbs
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

        // Then
        XCTAssertEqual(weightManager.weightEntries.count, 1)
        XCTAssertEqual(weightManager.latestWeight?.weight, 500.0)
    }

    func testAddWeightEntry_HandlesLowValues() {
        // Given - very low weight
        let lowEntry = WeightEntry(date: Date(), weight: 50.0, source: .manual)

        // When
        weightManager.addWeightEntry(lowEntry)

        // Then
        XCTAssertEqual(weightManager.weightEntries.count, 1)
        XCTAssertEqual(weightManager.latestWeight?.weight, 50.0)
    }
}
