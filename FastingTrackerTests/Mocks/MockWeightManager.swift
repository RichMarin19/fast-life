import Foundation
import Combine
@testable import FastLIFe

/// Mock WeightManager for unit testing ViewModels
/// Industry Pattern: Subclass-based mocking for testability
/// Reference: Apple WWDC 2017 "Testing in Xcode" - Subclass or protocol for mocks
/// Follows "simplest method first" principle: Subclassing avoids complex dependency injection
@MainActor
class MockWeightManager: WeightManager {
    // MARK: - Test Control Properties

    var addWeightEntryCalled = false
    var deleteWeightEntryCalled = false
    var lastAddedEntry: WeightEntry?
    var lastDeletedEntry: WeightEntry?

    // MARK: - Initialization
    // Uses WeightManager's convenience init() which handles all dependencies via singletons
    // Following Apple testing pattern: Leverage parent class initialization for simplicity

    init() {
        // Call parent's convenience init which uses HealthKitManager.shared and AppDataStore.shared
        super.init(
            healthKit: HealthKitManager.shared,
            dataStore: AppDataStore.shared,
            appSettings: AppSettings()
        )
        // Start with empty state for clean test environment
        self.weightEntries = []
        self.syncWithHealthKit = false
    }

    // MARK: - Override Methods for Testing (track calls for verification)

    override func addWeightEntry(_ entry: WeightEntry) {
        addWeightEntryCalled = true
        lastAddedEntry = entry

        // Simplified version without HealthKit sync for testing
        weightEntries.append(entry)
        weightEntries.sort { $0.date > $1.date }
    }

    override func deleteWeightEntry(_ entry: WeightEntry) {
        deleteWeightEntryCalled = true
        lastDeletedEntry = entry

        // Simplified version without HealthKit deletion for testing
        weightEntries.removeAll { $0.id == entry.id }
    }

    // MARK: - Override HealthKit Methods (No-op for testing)
    // Industry Pattern: Override external dependencies to prevent side effects
    // Reference: Apple WWDC 2017 "Testing in Xcode" - Stub external dependencies

    override func syncFromHealthKitHistorical(startDate: Date, completion: @escaping (Int, Error?) -> Void) {
        // No-op: Tests don't verify HealthKit sync logic
        completion(0, nil)
    }

    override func syncFromHealthKitWithReset(startDate: Date, completion: @escaping (Int, Error?) -> Void) {
        // No-op: Tests don't verify HealthKit sync logic
        completion(0, nil)
    }

    override func setSyncPreference(_ enabled: Bool) {
        // Simplified: Just update the property without triggering HealthKit authorization
        syncWithHealthKit = enabled
    }

    // MARK: - Test Helper Methods

    /// Reset all tracking flags for fresh test state
    func reset() {
        addWeightEntryCalled = false
        deleteWeightEntryCalled = false
        lastAddedEntry = nil
        lastDeletedEntry = nil
        weightEntries.removeAll()
        syncWithHealthKit = false
    }

    /// Set up test data with specified weight entries
    func setTestData(_ entries: [WeightEntry]) {
        weightEntries = entries.sorted { $0.date > $1.date }
    }
}
