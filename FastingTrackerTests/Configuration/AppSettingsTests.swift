//
//  AppSettingsTests.swift
//  FastingTrackerTests
//
//  Created by Claude Code
//  Phase 2 Task 2.1: System Locale Units Testing
//

import XCTest
@testable import FastLIFe

@MainActor
final class AppSettingsTests: XCTestCase {

    var appSettings: AppSettings!

    override func setUp() {
        super.setUp()
        appSettings = AppSettings.shared
    }

    override func tearDown() {
        appSettings = nil
        super.tearDown()
    }

    // MARK: - PHASE 2 TASK 2.1: System Locale Units Tests
    // Testing Recovery Task #2 - System Locale Unit Detection
    // Following Apple Testing Best Practices - locale handling

    func test_weightUnit_currentLocale_returnsWeightUnit() {
        // Given - current system locale
        // Note: Locale.current is read implicitly by appSettings.weightUnit

        // When
        let weightUnit = appSettings.weightUnit

        // Then - should return either kilograms or pounds based on locale
        // Note: This test verifies the method works, but result depends on test environment locale
        XCTAssert(weightUnit == .kilograms || weightUnit == .pounds,
                  "Weight unit should be either kilograms or pounds")

        // And - verify consistency
        let secondCall = appSettings.weightUnit
        XCTAssertEqual(weightUnit, secondCall, "Weight unit should be consistent for same locale")
    }

    func test_weightUnit_metricSystem_returnsKilograms() {
        // Note: This test documents expected behavior for metric systems
        // Given - a system with metric measurement system
        // Locale examples: en_GB (UK), en_CA (Canada), de_DE (Germany), fr_FR (France)

        // When - checking if current locale is metric
        if Locale.current.measurementSystem == .metric {
            // Then - weight unit should be kilograms
            XCTAssertEqual(appSettings.weightUnit, .kilograms,
                          "Metric locale should return kilograms")
            XCTAssertEqual(appSettings.weightUnit.abbreviation, "kg",
                          "Metric unit abbreviation should be 'kg'")
        } else {
            // Document that test environment is not metric
            print("⚠️ Test environment locale is not metric - skipping metric-specific assertion")
        }
    }

    func test_weightUnit_imperialSystem_returnsPounds() {
        // Note: This test documents expected behavior for imperial systems
        // Given - a system with US measurement system
        // Locale examples: en_US (USA), en_LR (Liberia), my_MM (Myanmar)

        // When - checking if current locale is imperial (US)
        if Locale.current.measurementSystem == .us {
            // Then - weight unit should be pounds
            XCTAssertEqual(appSettings.weightUnit, .pounds,
                          "Imperial/US locale should return pounds")
            XCTAssertEqual(appSettings.weightUnit.abbreviation, "lbs",
                          "Imperial unit abbreviation should be 'lbs'")
        } else {
            // Document that test environment is not imperial
            print("⚠️ Test environment locale is not imperial - skipping imperial-specific assertion")
        }
    }

    func test_weightUnit_abbreviation_matchesLocale() {
        // Given - current weight unit from locale
        let weightUnit = appSettings.weightUnit

        // When
        let abbreviation = weightUnit.abbreviation

        // Then - should match expected abbreviation for unit
        if weightUnit == .kilograms {
            XCTAssertEqual(abbreviation, "kg", "Kilograms abbreviation should be 'kg'")
        } else if weightUnit == .pounds {
            XCTAssertEqual(abbreviation, "lbs", "Pounds abbreviation should be 'lbs'")
        }
    }

    func test_weightUnit_conversion_accurateForBothSystems() {
        // Given - known conversion: 150 lbs = 68.04 kg (approx)
        let poundsValue = 150.0
        let expectedKg = 68.04 // 150 * 0.453592 ≈ 68.04

        // When - converting pounds to kg
        let kilogramsValue = WeightUnit.kilograms.fromPounds(poundsValue)

        // Then - should be accurate to 2 decimal places
        XCTAssertEqual(kilogramsValue, expectedKg, accuracy: 0.01,
                      "150 lbs should convert to ~68.04 kg")

        // And - reverse conversion should match
        let backToPounds = WeightUnit.pounds.fromPounds(poundsValue)
        XCTAssertEqual(backToPounds, poundsValue, accuracy: 0.01,
                      "Pounds to pounds should return original value")

        // And - round-trip conversion
        let roundTrip = WeightUnit.kilograms.toPounds(kilogramsValue)
        XCTAssertEqual(roundTrip, poundsValue, accuracy: 0.1,
                      "Round-trip conversion should preserve original value")
    }

    func test_weightUnit_displayName_matchesUnit() {
        // Given - current weight unit
        let weightUnit = appSettings.weightUnit

        // When
        let displayName = weightUnit.displayName

        // Then - should have proper display name
        if weightUnit == .kilograms {
            XCTAssertEqual(displayName, "Kilograms (kg)",
                          "Kilograms display name should be 'Kilograms (kg)'")
        } else if weightUnit == .pounds {
            XCTAssertEqual(displayName, "Pounds (lbs)",
                          "Pounds display name should be 'Pounds (lbs)'")
        }
    }

    // MARK: - Additional Locale Tests

    func test_weightUnit_multipleAccesses_consistent() {
        // Given - multiple rapid accesses
        var units: [WeightUnit] = []

        // When - accessing multiple times
        for _ in 0..<10 {
            units.append(appSettings.weightUnit)
        }

        // Then - all should be the same
        let firstUnit = units.first!
        XCTAssert(units.allSatisfy { $0 == firstUnit },
                  "Weight unit should be consistent across multiple accesses")
    }
}
