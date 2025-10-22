import Foundation
import Combine
@testable import Fast_lIFe

/// Mock WeightManager for unit testing ViewModels
/// Industry Pattern: Mock objects for isolated unit testing
/// Reference: Apple WWDC 2017 "Testing in Xcode" - Mock Dependencies
@MainActor
class MockWeightManager: ObservableObject {
    // MARK: - Published Properties (match WeightManager interface)

    @Published var weightEntries: [WeightEntry] = []
    @Published var syncWithHealthKit: Bool = false

    // MARK: - Test Control Properties

    var addWeightEntryCalled = false
    var deleteWeightEntryCalled = false
    var lastAddedEntry: WeightEntry?
    var lastDeletedEntry: WeightEntry?

    // MARK: - Mock Unit Conversion (matches WeightManager)

    private let appSettings = AppSettings.shared

    func displayWeight(for entry: WeightEntry) -> Double {
        return appSettings.weightUnit.fromPounds(entry.weight)
    }

    func convertToInternalUnit(_ value: Double) -> Double {
        return appSettings.weightUnit.toPounds(value)
    }

    var currentUnitAbbreviation: String {
        return appSettings.weightUnit.abbreviation
    }

    var currentUnitDisplayName: String {
        return appSettings.weightUnit.displayName
    }

    func convertWeightToDisplayUnit(_ weightInPounds: Double) -> Double {
        return appSettings.weightUnit.fromPounds(weightInPounds)
    }

    // MARK: - Mock Methods (track calls for verification)

    func addWeightEntry(_ entry: WeightEntry) {
        addWeightEntryCalled = true
        lastAddedEntry = entry
        weightEntries.append(entry)
        weightEntries.sort { $0.date > $1.date }
    }

    func deleteWeightEntry(_ entry: WeightEntry) {
        deleteWeightEntryCalled = true
        lastDeletedEntry = entry
        weightEntries.removeAll { $0.id == entry.id }
    }

    func addWeightEntryInPreferredUnit(weight: Double, bmi: Double? = nil, bodyFat: Double? = nil, date: Date = Date()) {
        let weightInPounds = appSettings.weightUnit.toPounds(weight)
        let entry = WeightEntry(date: date, weight: weightInPounds, bmi: bmi, bodyFat: bodyFat, source: .manual)
        addWeightEntry(entry)
    }

    func wouldCreateDuplicate(weight: Double, date: Date = Date()) -> Bool {
        let weightInPounds = appSettings.weightUnit.toPounds(weight)
        return weightEntries.contains(where: {
            abs($0.date.timeIntervalSince(date)) < 1800 && // Within 30 minutes
            abs($0.weight - weightInPounds) < 0.1 // Within 0.1 lbs
        })
    }

    // MARK: - Statistics (simplified for testing)

    var latestWeight: WeightEntry? {
        weightEntries.first
    }

    var weightTrend: Double? {
        guard weightEntries.count >= 2 else { return nil }
        let recentEntries = Array(weightEntries.prefix(7))
        guard recentEntries.count >= 2 else { return nil }
        return recentEntries.first!.weight - recentEntries.last!.weight
    }

    var averageWeight: Double? {
        guard !weightEntries.isEmpty else { return nil }
        let sum = weightEntries.map { $0.weight }.reduce(0.0, +)
        return sum / Double(weightEntries.count)
    }

    func weightChange(since date: Date) -> Double? {
        guard let latestEntry = latestWeight else { return nil }
        let calendar = Calendar.current

        for entry in weightEntries.reversed() {
            let comparison = calendar.compare(entry.date, to: date, toGranularity: .day)
            if comparison == .orderedAscending || comparison == .orderedSame {
                return latestEntry.weight - entry.weight
            }
        }

        return nil
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
