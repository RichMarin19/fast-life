import Foundation
import Combine
import HealthKit

class WeightManager: ObservableObject {
    @Published var weightEntries: [WeightEntry] = []
    @Published var syncWithHealthKit: Bool = true

    private let userDefaults = UserDefaults.standard
    private let weightEntriesKey = "weightEntries"
    private let syncHealthKitKey = "syncWithHealthKit"
    private var observerQuery: HKObserverQuery?

    init() {
        loadWeightEntries()
        loadSyncPreference()

        // Delay sync and observer setup to allow UI to render first
        // This prevents perceived slowness on app launch
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }

            // Automatically sync from HealthKit on launch if authorized and enabled
            if self.syncWithHealthKit && HealthKitManager.shared.isAuthorized {
                self.syncFromHealthKit()
            }

            // Setup observer for automatic updates
            self.setupHealthKitObserver()
        }
    }

    deinit {
        // Clean up observer when manager is deallocated
        if let query = observerQuery {
            HealthKitManager.shared.stopObserving(query: query)
        }
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
        print("\n⚙️  === SET WEIGHT SYNC PREFERENCE ===")
        print("Enabled: \(enabled)")

        syncWithHealthKit = enabled
        userDefaults.set(enabled, forKey: syncHealthKitKey)

        if enabled {
            // BLOCKER 5 FIX: Request WEIGHT authorization only (not all permissions)
            // Per Apple best practices: Request permissions only when needed, per domain
            // Reference: https://developer.apple.com/documentation/healthkit/protecting_user_privacy
            let isAuthorized = HealthKitManager.shared.isWeightAuthorized()
            print("Weight Authorization Status: \(isAuthorized ? "✅ Authorized" : "❌ Not Authorized")")

            if !isAuthorized {
                print("📱 Requesting WEIGHT authorization (granular)...")
                HealthKitManager.shared.requestWeightAuthorization { success, error in
                    if success {
                        print("✅ Weight authorization granted → syncing from HealthKit")
                        self.syncFromHealthKit()
                        self.setupHealthKitObserver()
                    } else {
                        print("❌ Weight authorization denied: \(String(describing: error))")
                    }
                }
            } else {
                print("✅ Already authorized → syncing from HealthKit")
                syncFromHealthKit()
                setupHealthKitObserver()
            }
        } else {
            print("⏭️  Sync disabled → stopping HealthKit observer")
            // Stop observing when sync is disabled
            if let query = observerQuery {
                HealthKitManager.shared.stopObserving(query: query)
                observerQuery = nil
            }
        }

        print("======================================\n")
    }

    // MARK: - HealthKit Observer

    private func setupHealthKitObserver() {
        // Only setup observer if sync is enabled and authorized
        guard syncWithHealthKit && HealthKitManager.shared.isAuthorized else { return }

        // Remove existing observer if any
        if let existingQuery = observerQuery {
            HealthKitManager.shared.stopObserving(query: existingQuery)
        }

        // Create observer query for weight data
        guard let weightType = HKObjectType.quantityType(forIdentifier: .bodyMass) else { return }

        let query = HKObserverQuery(sampleType: weightType, predicate: nil) { [weak self] query, completionHandler, error in
            if let error = error {
                print("Observer query error: \(error.localizedDescription)")
                completionHandler()
                return
            }

            // New weight data detected - sync from HealthKit
            print("New weight data detected in HealthKit - syncing...")
            DispatchQueue.main.async {
                self?.syncFromHealthKit()
            }

            // Must call completion handler
            completionHandler()
        }

        observerQuery = query
        HealthKitManager.shared.startObserving(query: query)
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
