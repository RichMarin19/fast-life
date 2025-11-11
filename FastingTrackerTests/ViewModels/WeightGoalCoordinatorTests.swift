import XCTest
import Combine
@testable import FastLIFe

@MainActor
final class WeightGoalCoordinatorTests: XCTestCase {

    func testGoalDisplayReformatsWhenMeasurementSystemChanges() {
        let localeProvider = MutableLocaleProvider(measurementSystem: .us, localeIdentifier: "en_US")
        let appSettings = AppSettings(localeProvider: localeProvider)
        let persistence = TestWeightPersistence()
        let weightManager = WeightManager(
            healthKit: MockHealthKitManager(),
            dataStore: MockDataStore(),
            appSettings: appSettings,
            persistence: persistence,
            syncCoordinator: WeightSyncCoordinator(),
            analytics: WeightAnalyticsService()
        )
        weightManager.setGoalWeight(170)

        let measurementProvider = StubMeasurementSystemProvider(system: .us, localeIdentifier: "en_US")
        let coordinator = WeightGoalCoordinator(
            weightManager: weightManager,
            measurementProvider: measurementProvider,
            locale: Locale(identifier: "en_US"),
            healthKitManager: MockHealthKitManager()
        )

        XCTAssertEqual(coordinator.weightGoalString, "170")

        localeProvider.update(measurementSystem: .metric, localeIdentifier: "en_GB")
        measurementProvider.update(system: .metric, localeIdentifier: "en_GB")

        let expectation = expectation(description: "Measurement update applied")
        DispatchQueue.main.async {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 0.5)

        XCTAssertEqual(coordinator.weightGoalString, weightManager.formattedDisplayWeight(weightManager.goalWeight))
    }

    func testStartWeightStringUpdatesWhenMeasurementChanges() {
        let localeProvider = MutableLocaleProvider(measurementSystem: .us, localeIdentifier: "en_US")
        let appSettings = AppSettings(localeProvider: localeProvider)
        let weightManager = WeightManager(
            healthKit: MockHealthKitManager(),
            dataStore: MockDataStore(),
            appSettings: appSettings,
            persistence: TestWeightPersistence(),
            syncCoordinator: MockWeightSyncCoordinator(),
            analytics: WeightAnalyticsService()
        )

        let measurementProvider = StubMeasurementSystemProvider(system: .us, localeIdentifier: "en_US")
        let coordinator = WeightGoalCoordinator(
            weightManager: weightManager,
            measurementProvider: measurementProvider,
            locale: Locale(identifier: "en_US"),
            healthKitManager: MockHealthKitManager()
        )

        coordinator.formatStartWeightInput("180")
        XCTAssertEqual(coordinator.startWeightString, "180")

        measurementProvider.update(system: .metric, localeIdentifier: "en_GB")

        let expectation = expectation(description: "Start weight updated")
        DispatchQueue.main.async {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 0.5)

        XCTAssertEqual(coordinator.startWeightString, weightManager.formattedDisplayWeight(180))
        XCTAssertEqual(coordinator.unitAbbreviation, weightManager.currentUnitAbbreviation)
    }
}

// MARK: - Test Doubles

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

    func update(system: Locale.MeasurementSystem, localeIdentifier: String) {
        currentLocale = Locale(identifier: localeIdentifier)
        subject.send(system)
    }
}

private final class TestWeightPersistence: WeightPersistenceManaging {
    var storedEntries: [WeightEntry] = []
    var syncPreference: Bool?
    var startWeightOverride: (weight: Double?, date: Date?) = (nil, nil)
    var milestoneCount: Int?
    var goalWeight: Double?

    func loadWeightEntries() -> [WeightEntry] {
        storedEntries
    }

    func saveWeightEntries(_ entries: [WeightEntry]) {
        storedEntries = entries
    }

    func loadSyncPreference() -> Bool? {
        syncPreference
    }

    func saveSyncPreference(_ value: Bool) {
        syncPreference = value
    }

    func loadStartWeightOverride() -> (weight: Double?, date: Date?) {
        startWeightOverride
    }

    func saveStartWeightOverride(weight: Double?, date: Date?) {
        startWeightOverride = (weight, date)
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

private final class MockWeightSyncCoordinator: WeightSyncCoordinating {
    func mergeNewEntries(currentEntries: inout [WeightEntry], healthKitEntries: [WeightEntry], duplicateChecker: (WeightEntry, WeightEntry) -> Bool) -> Int {
        0
    }

    func mergeHistoricalEntries(currentEntries: inout [WeightEntry], healthKitEntries: [WeightEntry], duplicateChecker: (WeightEntry, WeightEntry) -> Bool) -> Int {
        0
    }

    func reconcileAfterReset(currentEntries: inout [WeightEntry], healthKitEntries: [WeightEntry], duplicateChecker: (WeightEntry, WeightEntry) -> Bool) -> (added: Int, deleted: Int) {
        (0, 0)
    }
}
