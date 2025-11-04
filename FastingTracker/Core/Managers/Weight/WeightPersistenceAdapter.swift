import Foundation

protocol WeightPersistenceManaging {
    func loadWeightEntries() -> [WeightEntry]
    func saveWeightEntries(_ entries: [WeightEntry])

    func loadSyncPreference() -> Bool?
    func saveSyncPreference(_ value: Bool)

    func loadStartWeightOverride() -> (weight: Double?, date: Date?)
    func saveStartWeightOverride(weight: Double?, date: Date?)

    func loadMilestoneCount() -> Int?
    func saveMilestoneCount(_ count: Int)

    func loadGoalWeight() -> Double?
    func saveGoalWeight(_ weight: Double)
}

final class WeightPersistenceAdapter: WeightPersistenceManaging {
    private enum Keys {
        static let weightEntries = "weightEntries"
        static let syncHealthKit = "syncWithHealthKit"
        static let startWeight = "weightStartOverride"
        static let startWeightDate = "weightStartDate"
        static let legacyStartWeight = "startWeight"
        static let legacyStartDate = "startDate"
        static let milestoneCount = "weightMilestoneCount"
        static let goalWeight = "goalWeight"
    }

    private let defaults: ThreadSafeUserDefaults
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    init(defaults: ThreadSafeUserDefaults = ThreadSafeUserDefaults()) {
        self.defaults = defaults
    }

    func loadWeightEntries() -> [WeightEntry] {
        guard let data = defaults.data(forKey: Keys.weightEntries),
              let decoded = try? decoder.decode([WeightEntry].self, from: data) else {
            return []
        }
        return decoded.sorted { $0.date > $1.date }
    }

    func saveWeightEntries(_ entries: [WeightEntry]) {
        guard let encoded = try? encoder.encode(entries) else { return }
        defaults.set(encoded, forKey: Keys.weightEntries)
    }

    func loadSyncPreference() -> Bool? {
        guard defaults.object(forKey: Keys.syncHealthKit) != nil else {
            return nil
        }
        return defaults.bool(forKey: Keys.syncHealthKit)
    }

    func saveSyncPreference(_ value: Bool) {
        defaults.set(value, forKey: Keys.syncHealthKit)
    }

    func loadStartWeightOverride() -> (weight: Double?, date: Date?) {
        var weight: Double?
        var date: Date?

        if let stored = defaults.object(forKey: Keys.startWeight) as? Double, stored > 0 {
            weight = stored
        } else if let legacy = defaults.object(forKey: Keys.legacyStartWeight) as? Double, legacy > 0 {
            weight = legacy
            defaults.removeObject(forKey: Keys.legacyStartWeight)
        }

        if let storedDate = defaults.object(forKey: Keys.startWeightDate) as? Date {
            date = storedDate
        } else if let legacyDate = defaults.object(forKey: Keys.legacyStartDate) as? Date {
            date = legacyDate
            defaults.removeObject(forKey: Keys.legacyStartDate)
        }

        return (weight, date)
    }

    func saveStartWeightOverride(weight: Double?, date: Date?) {
        if let weight, weight > 0 {
            defaults.set(weight, forKey: Keys.startWeight)
            defaults.set(date, forKey: Keys.startWeightDate)
        } else {
            defaults.removeObject(forKey: Keys.startWeight)
            defaults.removeObject(forKey: Keys.startWeightDate)
        }
    }

    func loadMilestoneCount() -> Int? {
        defaults.object(forKey: Keys.milestoneCount) as? Int
    }

    func saveMilestoneCount(_ count: Int) {
        defaults.set(count, forKey: Keys.milestoneCount)
    }

    func loadGoalWeight() -> Double? {
        defaults.object(forKey: Keys.goalWeight) as? Double
    }

    func saveGoalWeight(_ weight: Double) {
        defaults.set(weight, forKey: Keys.goalWeight)
    }
}
