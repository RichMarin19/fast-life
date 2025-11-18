//
//  AppSettingsTests.swift
//  FastingTrackerTests
//
//  Created by Claude Code
//  Phase 2 Task 2.1: System Locale Units Testing
//

import XCTest
import Combine
@testable import FastLIFe

@MainActor
final class AppSettingsTests: XCTestCase {

    var appSettings: AppSettings!

    override func setUp() {
        super.setUp()
        LocaleTestProvider.reset()
        appSettings = makeSettings(metric: false)
    }

    override func tearDown() {
        appSettings = nil
        super.tearDown()
    }

    // MARK: - PHASE 2 TASK 2.1: System Locale Units Tests
    // Testing Recovery Task #2 - System Locale Unit Detection
    // Following Apple Testing Best Practices - locale handling

    func test_weightUnit_currentLocale_returnsWeightUnit() {
        // Given
        appSettings = makeSettings(metric: false)
        let weightUnit = appSettings.weightUnit

        // Then
        XCTAssertEqual(weightUnit, .pounds)
        XCTAssertEqual(appSettings.weightUnit, weightUnit)
    }

    func test_weightUnit_metricSystem_returnsKilograms() {
        appSettings = makeSettings(metric: true)
        XCTAssertEqual(appSettings.weightUnit, .kilograms)
        XCTAssertEqual(appSettings.weightUnit.abbreviation, "kg")
    }

    func test_weightUnit_imperialSystem_returnsPounds() {
        appSettings = makeSettings(metric: false)
        XCTAssertEqual(appSettings.weightUnit, .pounds)
        XCTAssertEqual(appSettings.weightUnit.abbreviation, "lbs")
    }

    func test_weightUnit_abbreviation_matchesLocale() {
        // Given - current weight unit from locale
        appSettings = makeSettings(metric: false)
        XCTAssertEqual(appSettings.weightUnit.abbreviation, "lbs")

        appSettings = makeSettings(metric: true)
        XCTAssertEqual(appSettings.weightUnit.abbreviation, "kg")
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
        appSettings = makeSettings(metric: true)
        XCTAssertEqual(appSettings.weightUnit.displayName, "Kilograms (kg)")

        appSettings = makeSettings(metric: false)
        XCTAssertEqual(appSettings.weightUnit.displayName, "Pounds (lbs)")
    }

    // MARK: - Additional Locale Tests

    func test_weightUnit_multipleAccesses_consistent() {
        appSettings = makeSettings(metric: false)
        let first = appSettings.weightUnit
        for _ in 0..<10 {
            XCTAssertEqual(appSettings.weightUnit, first)
        }
    }
}

// MARK: - Locale Test Provider

private final class LocaleTestProvider: LocaleProviding {
    private static var isMetric: Bool = false

    static var current: LocaleTestProvider {
        LocaleTestProvider(metric: isMetric)
    }

    static func set(metric: Bool) {
        isMetric = metric
    }

    static func reset() {
        isMetric = false
    }

    init(metric: Bool) {
        self.metric = metric
    }

    private let metric: Bool

    var measurementSystem: Locale.MeasurementSystem {
        metric ? .metric : .us
    }

    var localeIdentifier: String {
        metric ? "en_GB" : "en_US"
    }

}

private func makeSettings(metric: Bool) -> AppSettings {
    LocaleTestProvider.set(metric: metric)
    let measurementProvider = StubMeasurementSystemProvider(
        system: metric ? .metric : .us,
        localeIdentifier: metric ? "en_GB" : "en_US"
    )
    return AppSettings(
        localeProvider: LocaleTestProvider.current,
        measurementSystemProvider: measurementProvider
    )
}

private final class StubMeasurementSystemProvider: MeasurementSystemProviding {
    private let subject: CurrentValueSubject<Locale.MeasurementSystem, Never>
    private var currentLocale: Locale

    init(system: Locale.MeasurementSystem, localeIdentifier: String) {
        self.subject = CurrentValueSubject(system)
        self.currentLocale = Locale(identifier: localeIdentifier)
    }

    var currentUnit: WeightUnit {
        subject.value == .metric ? .kilograms : .pounds
    }

    var locale: Locale {
        currentLocale
    }

    var currentMeasurementSystem: Locale.MeasurementSystem {
        subject.value
    }

    var measurementSystemPublisher: AnyPublisher<Locale.MeasurementSystem, Never> {
        subject.eraseToAnyPublisher()
    }

    func refresh() {
        subject.send(subject.value)
    }
}
