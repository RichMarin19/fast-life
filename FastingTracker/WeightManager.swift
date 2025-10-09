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

        // REMOVED auto-sync on init per Apple HealthKit Best Practices
        // Sync only when user explicitly enables it via setSyncPreference()
        // or when view explicitly calls syncFromHealthKit()
        // Reference: https://developer.apple.com/documentation/healthkit/setting_up_healthkit

        // Setup observer if sync is already enabled (app restart scenario)
        if syncWithHealthKit && HealthKitManager.shared.isWeightAuthorized() {
            setupHealthKitObserver()
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
                    AppLogger.error("Failed to sync weight to HealthKit", category: AppLogger.weightTracking, error: error)
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
                    AppLogger.error("Failed to delete weight from HealthKit", category: AppLogger.weightTracking, error: error)
                }
            }
        }
    }

    // MARK: - Sync with HealthKit

    func syncFromHealthKit(startDate: Date? = nil, completion: ((Int, Error?) -> Void)? = nil) {
        guard syncWithHealthKit else {
            completion?(0, NSError(domain: "WeightManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "HealthKit sync is disabled"]))
            return
        }

        // Default to fetching last 365 days if no start date provided
        let start = startDate ?? Calendar.current.date(byAdding: .day, value: -365, to: Date())!

        HealthKitManager.shared.fetchWeightData(startDate: start) { [weak self] healthKitEntries in
            guard let self = self else {
                completion?(0, NSError(domain: "WeightManager", code: 2, userInfo: [NSLocalizedDescriptionKey: "WeightManager instance deallocated"]))
                return
            }

            // Track newly added entries for accurate reporting
            var newlyAddedCount = 0

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
                    newlyAddedCount += 1
                }
            }

            // Sort by date (most recent first)
            self.weightEntries.sort { $0.date > $1.date }
            self.saveWeightEntries()

            // Report actual sync results
            AppLogger.info("HealthKit sync completed: \(newlyAddedCount) new weight entries added", category: AppLogger.weightTracking)

            DispatchQueue.main.async {
                completion?(newlyAddedCount, nil)
            }
        }
    }

    /// Sync all historical weight data from HealthKit
    /// Following Apple HealthKit Programming Guide: Comprehensive data import for user choice
    /// Used when user selects "Import All Historical Data" option
    func syncFromHealthKitHistorical(startDate: Date, completion: @escaping (Int, Error?) -> Void) {
        guard syncWithHealthKit else {
            completion(0, NSError(domain: "WeightManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "HealthKit sync is disabled"]))
            return
        }

        AppLogger.info("Starting historical weight sync from \(startDate)", category: AppLogger.weightTracking)

        HealthKitManager.shared.fetchWeightDataHistorical(startDate: startDate) { [weak self] healthKitEntries in
            guard let self = self else {
                completion(0, NSError(domain: "WeightManager", code: 2, userInfo: [NSLocalizedDescriptionKey: "WeightManager instance deallocated"]))
                return
            }

            // Track newly added entries for accurate reporting
            var newlyAddedCount = 0

            // Merge HealthKit entries with local entries using robust deduplication
            for hkEntry in healthKitEntries {
                // More comprehensive duplicate check for historical data
                let isDuplicate = self.weightEntries.contains(where: {
                    // Check if entry already exists (by date, time, weight, and source)
                    $0.source == .healthKit &&
                    abs($0.date.timeIntervalSince(hkEntry.date)) < 300 && // Within 5 minutes (more flexible for historical)
                    abs($0.weight - hkEntry.weight) < 0.2 // Within 0.2 lbs (account for rounding)
                })

                if !isDuplicate {
                    // Add new HealthKit entry from historical import
                    self.weightEntries.append(hkEntry)
                    newlyAddedCount += 1
                }
            }

            // Sort by date (most recent first)
            self.weightEntries.sort { $0.date > $1.date }
            self.saveWeightEntries()

            // Report actual sync results
            AppLogger.info("Historical HealthKit sync completed: \(newlyAddedCount) new weight entries imported from \(healthKitEntries.count) total entries", category: AppLogger.weightTracking)

            DispatchQueue.main.async {
                completion(newlyAddedCount, nil)
            }
        }
    }

    func setSyncPreference(_ enabled: Bool) {
        AppLogger.info("Setting weight sync preference to \(enabled)", category: AppLogger.weightTracking)

        syncWithHealthKit = enabled
        userDefaults.set(enabled, forKey: syncHealthKitKey)

        if enabled {
            // BLOCKER 5 FIX: Request WEIGHT authorization only (not all permissions)
            // Per Apple best practices: Request permissions only when needed, per domain
            // Reference: https://developer.apple.com/documentation/healthkit/protecting_user_privacy
            let isAuthorized = HealthKitManager.shared.isAuthorized
            AppLogger.info("Comprehensive HealthKit authorization status: \(isAuthorized ? "granted" : "denied")", category: AppLogger.weightTracking)

            if !isAuthorized {
                AppLogger.info("Requesting comprehensive HealthKit authorization", category: AppLogger.weightTracking)
                HealthKitManager.shared.requestAuthorization { success, error in
                    if success {
                        AppLogger.info("Comprehensive HealthKit authorization granted, syncing weight from HealthKit", category: AppLogger.weightTracking)
                        self.syncFromHealthKit(completion: nil)
                        self.setupHealthKitObserver()
                    } else {
                        AppLogger.error("Comprehensive HealthKit authorization failed", category: AppLogger.weightTracking, error: error)
                        // Record authorization failure for production debugging
                        if let error = error {
                            CrashReportManager.shared.recordWeightError(error, context: [
                                "operation": "requestComprehensiveAuthorization"
                            ])
                        }
                    }
                }
            } else {
                AppLogger.info("Already authorized, syncing from HealthKit", category: AppLogger.weightTracking)
                syncFromHealthKit(completion: nil)
                setupHealthKitObserver()
            }
        } else {
            AppLogger.info("Weight sync disabled, stopping HealthKit observer", category: AppLogger.weightTracking)
            // Stop observing when sync is disabled
            if let query = observerQuery {
                HealthKitManager.shared.stopObserving(query: query)
                observerQuery = nil
            }
        }
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
                AppLogger.error("Weight observer query error", category: AppLogger.weightTracking, error: error)
                completionHandler()
                return
            }

            // New weight data detected - sync from HealthKit
            AppLogger.info("New weight data detected in HealthKit, syncing", category: AppLogger.weightTracking)
            DispatchQueue.main.async {
                self?.syncFromHealthKit(completion: nil)
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
