import Foundation
import Combine
import HealthKit

class SleepManager: ObservableObject {
    @Published var sleepEntries: [SleepEntry] = []
    @Published var syncWithHealthKit: Bool = true

    private let userDefaults = UserDefaults.standard
    private let sleepEntriesKey = "sleepEntries"
    private let syncHealthKitKey = "syncSleepWithHealthKit"
    private var observerQuery: HKObserverQuery?

    init() {
        loadSleepEntries()
        loadSyncPreference()

        // Delay sync and observer setup to allow UI to render first
        // This prevents perceived slowness on app launch (same pattern as WeightManager)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }

            // Automatically sync from HealthKit on launch if authorized and enabled (check sleep-specific authorization)
            if self.syncWithHealthKit && HealthKitManager.shared.isSleepAuthorized() {
                self.syncFromHealthKit()
            }

            // Setup observer for automatic updates
            self.setupHealthKitObserver()
        }
    }

    deinit {
        // Clean up observer when manager is deallocated
        if let query = observerQuery {
            HealthKitManager.shared.stopObservingSleep(query: query)
        }
    }

    // MARK: - Add/Update Sleep Entry

    func addSleepEntry(_ entry: SleepEntry) {
        // Validate that wake time is after bed time
        guard entry.wakeTime > entry.bedTime else {
            print("Invalid sleep entry: wake time must be after bed time")
            return
        }

        sleepEntries.append(entry)

        // Sort by wake time (most recent first)
        sleepEntries.sort { $0.wakeTime > $1.wakeTime }

        saveSleepEntries()

        // Sync to HealthKit if enabled and this is a manual entry
        if syncWithHealthKit && entry.source == .manual {
            HealthKitManager.shared.saveSleep(
                bedTime: entry.bedTime,
                wakeTime: entry.wakeTime,
                completion: { success, error in
                    if !success {
                        print("Failed to sync sleep to HealthKit: \(String(describing: error))")
                    }
                }
            )
        }
    }

    // MARK: - Delete Sleep Entry

    func deleteSleepEntry(_ entry: SleepEntry) {
        sleepEntries.removeAll { $0.id == entry.id }
        saveSleepEntries()

        // Delete from HealthKit if this was synced from HealthKit
        if syncWithHealthKit && entry.source == .healthKit {
            HealthKitManager.shared.deleteSleep(
                bedTime: entry.bedTime,
                wakeTime: entry.wakeTime,
                completion: { success, error in
                    if !success {
                        print("Failed to delete sleep from HealthKit: \(String(describing: error))")
                    }
                }
            )
        }
    }

    // MARK: - Sync with HealthKit

    func syncFromHealthKit(startDate: Date? = nil) {
        guard syncWithHealthKit else { return }

        // Default to fetching last 30 days if no start date provided
        let start = startDate ?? Calendar.current.date(byAdding: .day, value: -30, to: Date())!

        HealthKitManager.shared.fetchSleepData(startDate: start) { [weak self] healthKitEntries in
            guard let self = self else { return }

            // Merge HealthKit entries with local entries
            for hkEntry in healthKitEntries {
                // Check if we already have this exact entry (by bed time and wake time)
                let isDuplicate = self.sleepEntries.contains(where: {
                    $0.source == .healthKit &&
                    abs($0.bedTime.timeIntervalSince(hkEntry.bedTime)) < 60 && // Within 1 minute
                    abs($0.wakeTime.timeIntervalSince(hkEntry.wakeTime)) < 60   // Within 1 minute
                })

                if !isDuplicate {
                    self.sleepEntries.append(hkEntry)
                }
            }

            // Sort by wake time (most recent first)
            self.sleepEntries.sort { $0.wakeTime > $1.wakeTime }
            self.saveSleepEntries()
        }
    }

    func setSyncPreference(_ enabled: Bool) {
        syncWithHealthKit = enabled
        userDefaults.set(enabled, forKey: syncHealthKitKey)

        if enabled {
            // Request HealthKit authorization if needed (check sleep-specific authorization)
            if !HealthKitManager.shared.isSleepAuthorized() {
                HealthKitManager.shared.requestAuthorization { success, error in
                    if success {
                        self.syncFromHealthKit()
                        self.setupHealthKitObserver()
                    }
                }
            } else {
                syncFromHealthKit()
                setupHealthKitObserver()
            }
        } else {
            // Stop observing when sync is disabled
            if let query = observerQuery {
                HealthKitManager.shared.stopObservingSleep(query: query)
                observerQuery = nil
            }
        }
    }

    // MARK: - HealthKit Observer

    private func setupHealthKitObserver() {
        // Only setup observer if sync is enabled and authorized (check sleep-specific authorization)
        guard syncWithHealthKit && HealthKitManager.shared.isSleepAuthorized() else { return }

        // Remove existing observer if any
        if let existingQuery = observerQuery {
            HealthKitManager.shared.stopObservingSleep(query: existingQuery)
        }

        // Create observer query for sleep data
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return }

        let query = HKObserverQuery(sampleType: sleepType, predicate: nil) { [weak self] query, completionHandler, error in
            if let error = error {
                print("Sleep observer query error: \(error.localizedDescription)")
                completionHandler()
                return
            }

            // New sleep data detected - sync from HealthKit
            print("New sleep data detected in HealthKit - syncing...")
            DispatchQueue.main.async {
                self?.syncFromHealthKit()
            }

            // Must call completion handler
            completionHandler()
        }

        observerQuery = query
        HealthKitManager.shared.startObservingSleep(query: query)
    }

    // MARK: - Statistics

    /// Latest sleep entry
    var latestSleep: SleepEntry? {
        sleepEntries.first
    }

    /// Average sleep duration in hours over last 7 days
    var averageSleepHours: Double? {
        guard !sleepEntries.isEmpty else { return nil }

        let calendar = Calendar.current
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: Date())!

        let recentEntries = sleepEntries.filter { $0.wakeTime >= sevenDaysAgo }
        guard !recentEntries.isEmpty else { return nil }

        let totalHours = recentEntries.reduce(0.0) { $0 + ($1.duration / 3600) }
        return totalHours / Double(recentEntries.count)
    }

    /// Sleep trend (comparing last 7 days to previous 7 days)
    var sleepTrend: Double? {
        let calendar = Calendar.current
        let today = Date()
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: today)!
        let fourteenDaysAgo = calendar.date(byAdding: .day, value: -14, to: today)!

        let recentEntries = sleepEntries.filter { $0.wakeTime >= sevenDaysAgo && $0.wakeTime <= today }
        let olderEntries = sleepEntries.filter { $0.wakeTime >= fourteenDaysAgo && $0.wakeTime < sevenDaysAgo }

        guard !recentEntries.isEmpty && !olderEntries.isEmpty else { return nil }

        let recentAvg = recentEntries.reduce(0.0) { $0 + ($1.duration / 3600) } / Double(recentEntries.count)
        let olderAvg = olderEntries.reduce(0.0) { $0 + ($1.duration / 3600) } / Double(olderEntries.count)

        return recentAvg - olderAvg
    }

    /// Get sleep entries for a specific date range
    func sleepEntries(from startDate: Date, to endDate: Date) -> [SleepEntry] {
        sleepEntries.filter { $0.wakeTime >= startDate && $0.wakeTime <= endDate }
    }

    /// Last night's sleep (most recent entry within last 24 hours)
    var lastNightSleep: SleepEntry? {
        let calendar = Calendar.current
        let yesterday = calendar.date(byAdding: .day, value: -1, to: Date())!

        return sleepEntries.first(where: { $0.wakeTime >= yesterday })
    }

    // MARK: - Persistence

    private func saveSleepEntries() {
        if let encoded = try? JSONEncoder().encode(sleepEntries) {
            userDefaults.set(encoded, forKey: sleepEntriesKey)
        }
    }

    private func loadSleepEntries() {
        guard let data = userDefaults.data(forKey: sleepEntriesKey),
              let entries = try? JSONDecoder().decode([SleepEntry].self, from: data) else {
            return
        }
        sleepEntries = entries.sorted { $0.wakeTime > $1.wakeTime }
    }

    private func loadSyncPreference() {
        // Default to true if not set
        if userDefaults.object(forKey: syncHealthKitKey) != nil {
            syncWithHealthKit = userDefaults.bool(forKey: syncHealthKitKey)
        }
    }
}
