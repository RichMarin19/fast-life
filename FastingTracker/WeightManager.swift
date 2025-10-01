import Foundation
import Combine

class WeightManager: ObservableObject {
    @Published var weightEntries: [WeightEntry] = []
    @Published var syncWithHealthKit: Bool = true

    private let userDefaults = UserDefaults.standard
    private let weightEntriesKey = "weightEntries"
    private let syncHealthKitKey = "syncWithHealthKit"

    init() {
        loadWeightEntries()
        loadSyncPreference()
    }

    // MARK: - Add/Update Weight Entry

    func addWeightEntry(_ entry: WeightEntry) {
        // Simply add the entry - allow multiple entries per day
        weightEntries.append(entry)

        // Sort by date (most recent first)
        weightEntries.sort { $0.date > $1.date }

        saveWeightEntries()

        // Sync to HealthKit if enabled and this is a manual entry
        if syncWithHealthKit && entry.source == .manual {
            HealthKitManager.shared.saveWeight(weight: entry.weight, bmi: entry.bmi, bodyFat: entry.bodyFat, date: entry.date) { success, error in
                if !success {
                    print("Failed to sync weight to HealthKit: \(String(describing: error))")
                }
            }
        }
    }

    // MARK: - Delete Weight Entry

    func deleteWeightEntry(_ entry: WeightEntry) {
        weightEntries.removeAll { $0.id == entry.id }
        saveWeightEntries()

        // Delete from HealthKit if this was synced from HealthKit
        if syncWithHealthKit && entry.source == .healthKit {
            HealthKitManager.shared.deleteWeight(for: entry.date) { success, error in
                if !success {
                    print("Failed to delete weight from HealthKit: \(String(describing: error))")
                }
            }
        }
    }

    // MARK: - Sync with HealthKit

    func syncFromHealthKit(startDate: Date? = nil) {
        guard syncWithHealthKit else { return }

        // Default to fetching last 365 days if no start date provided
        let start = startDate ?? Calendar.current.date(byAdding: .day, value: -365, to: Date())!

        HealthKitManager.shared.fetchWeightData(startDate: start) { [weak self] healthKitEntries in
            guard let self = self else { return }

            // Merge HealthKit entries with local entries
            for hkEntry in healthKitEntries {
                // Check if we already have this exact entry (by date AND time, not just day)
                let isDuplicate = self.weightEntries.contains(where: {
                    $0.source == .healthKit &&
                    abs($0.date.timeIntervalSince(hkEntry.date)) < 60 && // Within 1 minute
                    abs($0.weight - hkEntry.weight) < 0.1 // Within 0.1 lbs
                })

                if !isDuplicate {
                    // Add new HealthKit entry (allows multiple per day)
                    self.weightEntries.append(hkEntry)
                }
            }

            // Sort by date (most recent first)
            self.weightEntries.sort { $0.date > $1.date }
            self.saveWeightEntries()
        }
    }

    func setSyncPreference(_ enabled: Bool) {
        syncWithHealthKit = enabled
        userDefaults.set(enabled, forKey: syncHealthKitKey)

        if enabled {
            // Request HealthKit authorization if needed
            if !HealthKitManager.shared.isAuthorized {
                HealthKitManager.shared.requestAuthorization { success, error in
                    if success {
                        self.syncFromHealthKit()
                    }
                }
            } else {
                syncFromHealthKit()
            }
        }
    }

    // MARK: - Statistics

    var latestWeight: WeightEntry? {
        weightEntries.first
    }

    var weightTrend: Double? {
        guard weightEntries.count >= 2 else { return nil }

        let recentEntries = Array(weightEntries.prefix(7)) // Last 7 entries
        guard recentEntries.count >= 2 else { return nil }

        let oldestRecent = recentEntries.last!.weight
        let newest = recentEntries.first!.weight

        return newest - oldestRecent
    }

    var averageWeight: Double? {
        guard !weightEntries.isEmpty else { return nil }

        // Optimized: use lazy to avoid creating intermediate array
        let sum = weightEntries.lazy.map { $0.weight }.reduce(0.0, +)
        return sum / Double(weightEntries.count)
    }

    func weightChange(since date: Date) -> Double? {
        guard let latestEntry = latestWeight else { return nil }

        let calendar = Calendar.current

        // Optimized: Since weightEntries is sorted newest first, iterate backwards
        // to find oldest entry that matches the date (more efficient than filter + last)
        for entry in weightEntries.reversed() {
            let comparison = calendar.compare(entry.date, to: date, toGranularity: .day)
            if comparison == .orderedAscending || comparison == .orderedSame {
                return latestEntry.weight - entry.weight
            }
        }

        return nil
    }

    // MARK: - Persistence

    private func saveWeightEntries() {
        if let encoded = try? JSONEncoder().encode(weightEntries) {
            userDefaults.set(encoded, forKey: weightEntriesKey)
        }
    }

    private func loadWeightEntries() {
        guard let data = userDefaults.data(forKey: weightEntriesKey),
              let entries = try? JSONDecoder().decode([WeightEntry].self, from: data) else {
            return
        }
        weightEntries = entries.sorted { $0.date > $1.date }
    }

    private func loadSyncPreference() {
        // Default to true if not set
        if userDefaults.object(forKey: syncHealthKitKey) != nil {
            syncWithHealthKit = userDefaults.bool(forKey: syncHealthKitKey)
        }
    }
}
