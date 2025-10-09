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

        // REMOVED auto-sync on init per Apple HealthKit Best Practices
        // Sync only when user explicitly enables it via setSyncPreference()
        // or when view explicitly calls syncFromHealthKit()
        // Reference: https://developer.apple.com/documentation/healthkit/setting_up_healthkit

        // Setup observer if sync is already enabled (app restart scenario)
        if syncWithHealthKit && HealthKitManager.shared.isSleepAuthorized() {
            setupHealthKitObserver()
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
        let duration = entry.duration / 3600
        AppLogger.info("Adding sleep entry - duration: \(String(format: "%.1fh", duration)), source: \(entry.source)", category: AppLogger.sleep)

        // ROADMAP REQUIREMENT: Validate inserts/updates and clamp ranges
        // Following Apple input validation best practices
        // Reference: https://developer.apple.com/documentation/foundation/dateformatter/creating_data_formatters

        // Validate that wake time is after bed time
        guard entry.wakeTime > entry.bedTime else {
            AppLogger.error("Invalid sleep entry: wake time must be after bed time", category: AppLogger.sleep)
            return
        }

        // Clamp sleep duration to reasonable range (30 minutes to 16 hours)
        let minDuration: TimeInterval = 1800 // 30 minutes
        let maxDuration: TimeInterval = 57600 // 16 hours
        let actualDuration = entry.duration

        guard actualDuration >= minDuration && actualDuration <= maxDuration else {
            let hours = actualDuration / 3600
            AppLogger.error("Invalid sleep duration: \(String(format: "%.1f", hours))h (must be 0.5-16h)", category: AppLogger.sleep)
            return
        }

        // ROADMAP REQUIREMENT: Add dedupe guards for entries in the same time window
        // Following Apple duplicate detection pattern
        if isDuplicate(entry: entry, timeWindow: 7200) { // 2 hour window
            AppLogger.warning("Prevented duplicate sleep entry within 2 hours", category: AppLogger.sleep)
            return
        }

        sleepEntries.append(entry)

        // Sort by wake time (most recent first)
        sleepEntries.sort { $0.wakeTime > $1.wakeTime }

        saveSleepEntries()

        // Sync to HealthKit if enabled and this is a manual entry
        // NOTE: HealthKit entries (source == .healthKit) are NOT synced back (would create duplicates)
        if syncWithHealthKit && entry.source == .manual {
            AppLogger.info("Syncing manual sleep entry to HealthKit", category: AppLogger.sleep)
            HealthKitManager.shared.saveSleep(
                bedTime: entry.bedTime,
                wakeTime: entry.wakeTime,
                completion: { success, error in
                    if success {
                        AppLogger.info("Sleep synced to HealthKit", category: AppLogger.sleep)
                    } else {
                        AppLogger.error("Failed to sync sleep to HealthKit", category: AppLogger.sleep, error: error)
                    }
                }
            )
        } else if !syncWithHealthKit {
            AppLogger.info("Skipped HealthKit sync (disabled)", category: AppLogger.sleep)
        } else {
            AppLogger.info("Skipped HealthKit sync (already from HealthKit)", category: AppLogger.sleep)
        }

        AppLogger.info("Sleep entry added to local storage", category: AppLogger.sleep)
    }

    // MARK: - Validation Methods
    // Following Apple input validation pattern for sleep data
    // Reference: https://developer.apple.com/documentation/healthkit/hkcategorytype

    /// Check if a potential sleep entry would be a duplicate within time window
    /// Following roadmap requirement for dedupe guards
    private func isDuplicate(entry: SleepEntry, timeWindow: TimeInterval) -> Bool {
        return sleepEntries.contains { existingEntry in
            // Check for overlapping sleep periods within the time window
            let bedTimeOverlap = abs(entry.bedTime.timeIntervalSince(existingEntry.bedTime)) < timeWindow
            let wakeTimeOverlap = abs(entry.wakeTime.timeIntervalSince(existingEntry.wakeTime)) < timeWindow
            return bedTimeOverlap && wakeTimeOverlap
        }
    }

    /// Validate if sleep entry can be added (public method for UI validation)
    func canAddSleepEntry(bedTime: Date, wakeTime: Date) -> Bool {
        // Check time validity
        guard wakeTime > bedTime else { return false }

        // Check duration validity
        let duration = wakeTime.timeIntervalSince(bedTime)
        let minDuration: TimeInterval = 1800 // 30 minutes
        let maxDuration: TimeInterval = 57600 // 16 hours
        guard duration >= minDuration && duration <= maxDuration else { return false }

        // Check for duplicates
        let tempEntry = SleepEntry(bedTime: bedTime, wakeTime: wakeTime, source: .manual)
        return !isDuplicate(entry: tempEntry, timeWindow: 7200)
    }

    /// Get validation errors for sleep entry (for UI feedback)
    func validateSleepEntry(bedTime: Date, wakeTime: Date) -> String? {
        guard wakeTime > bedTime else {
            return "Wake time must be after bed time"
        }

        let duration = wakeTime.timeIntervalSince(bedTime)

        if duration < 1800 {
            return "Sleep duration must be at least 30 minutes"
        }

        if duration > 57600 {
            return "Sleep duration cannot exceed 16 hours"
        }

        let tempEntry = SleepEntry(bedTime: bedTime, wakeTime: wakeTime, source: .manual)
        if isDuplicate(entry: tempEntry, timeWindow: 7200) {
            return "A sleep entry already exists within 2 hours of this time"
        }

        return nil // No validation errors
    }

    // MARK: - Delete Sleep Entry

    func deleteSleepEntry(_ entry: SleepEntry) {
        AppLogger.info("Deleting sleep entry - source: \(entry.source)", category: AppLogger.sleep)

        sleepEntries.removeAll { $0.id == entry.id }
        saveSleepEntries()

        // CRITICAL FIX (Blocker 4): Delete from HealthKit for ALL entries that could exist there
        // Per Apple HealthKit best practices: maintain add/delete symmetry
        // Reference: https://developer.apple.com/documentation/healthkit/hkhealthstore/1614158-delete
        //
        // Previous Bug: Only deleted if source == .healthKit
        // Problem: Manual entries (source = .manual) ARE synced TO HealthKit on add (line 57-67)
        //          but were NOT deleted FROM HealthKit on remove → orphaned HealthKit entries
        //
        // Fixed: Delete from HealthKit for BOTH manual and HealthKit-sourced entries
        //        since both can exist in HealthKit database
        if syncWithHealthKit {
            AppLogger.info("Attempting HealthKit deletion", category: AppLogger.sleep)
            HealthKitManager.shared.deleteSleep(
                bedTime: entry.bedTime,
                wakeTime: entry.wakeTime,
                completion: { success, error in
                    if success {
                        AppLogger.info("Sleep deleted from HealthKit", category: AppLogger.sleep)
                    } else {
                        // This is not necessarily an error - entry might not exist in HealthKit
                        // (e.g., if it was added before sync was enabled)
                        AppLogger.info("HealthKit deletion returned false (may not exist)", category: AppLogger.sleep)
                    }
                }
            )
        } else {
            AppLogger.info("Skipped HealthKit deletion (sync disabled)", category: AppLogger.sleep)
        }

        AppLogger.info("Sleep entry deleted from local storage", category: AppLogger.sleep)
    }

    // MARK: - Sync with HealthKit

    func syncFromHealthKit(startDate: Date? = nil) {
        guard syncWithHealthKit else { return }

        // Default to fetching last 30 days if no start date provided
        guard let start = startDate ?? Calendar.current.date(byAdding: .day, value: -30, to: Date()) else {
            AppLogger.logSafetyWarning("Failed to calculate 30 days ago date for HealthKit sync")
            return // Cannot sync without valid start date
        }

        HealthKitManager.shared.fetchSleepData(startDate: start) { [weak self] healthKitEntries in
            guard let self = self else { return }

            AppLogger.info("Fetched \(healthKitEntries.count) sleep entries from HealthKit", category: AppLogger.sleep)

            // Merge HealthKit entries with local entries
            var addedCount = 0
            for hkEntry in healthKitEntries {
                // CRITICAL FIX (Blocker 4 - Duplicate Prevention):
                // Check if we already have this exact entry by TIME ONLY (not source)
                // Previous Bug: Checked source == .healthKit which failed when comparing manual vs synced entries
                // Problem: Manual entry (source=.manual) syncs TO HealthKit → observer fires →
                //          syncFromHealthKit() pulls it back (source=.healthKit) → duplicate check fails
                // Fixed: Match by time ONLY, regardless of source
                // Reference: https://developer.apple.com/documentation/healthkit/hkobject/1614183-startdate
                let isDuplicate = self.sleepEntries.contains(where: {
                    abs($0.bedTime.timeIntervalSince(hkEntry.bedTime)) < 60 && // Within 1 minute
                    abs($0.wakeTime.timeIntervalSince(hkEntry.wakeTime)) < 60   // Within 1 minute
                })

                if !isDuplicate {
                    self.sleepEntries.append(hkEntry)
                    addedCount += 1
                }
            }

            if addedCount > 0 {
                AppLogger.info("Added \(addedCount) new sleep entries", category: AppLogger.sleep)
            }

            // Sort by wake time (most recent first)
            self.sleepEntries.sort { $0.wakeTime > $1.wakeTime }
            self.saveSleepEntries()
        }
    }

    func setSyncPreference(_ enabled: Bool) {
        AppLogger.info("Setting sleep sync preference to \(enabled)", category: AppLogger.sleep)

        syncWithHealthKit = enabled
        userDefaults.set(enabled, forKey: syncHealthKitKey)

        if enabled {
            // BLOCKER 5 FIX: Request SLEEP authorization only (not all permissions)
            // Per Apple best practices: Request permissions only when needed, per domain
            // Reference: https://developer.apple.com/documentation/healthkit/protecting_user_privacy
            let isAuthorized = HealthKitManager.shared.isSleepAuthorized()
            AppLogger.info("Sleep authorization status: \(isAuthorized ? "granted" : "denied")", category: AppLogger.sleep)

            if !isAuthorized {
                AppLogger.info("Requesting sleep authorization", category: AppLogger.sleep)
                HealthKitManager.shared.requestSleepAuthorization { success, error in
                    if success {
                        AppLogger.info("Sleep authorization granted, syncing from HealthKit", category: AppLogger.sleep)
                        self.syncFromHealthKit()
                        self.setupHealthKitObserver()
                    } else {
                        AppLogger.error("Sleep authorization failed", category: AppLogger.sleep, error: error)
                    }
                }
            } else {
                AppLogger.info("Already authorized, syncing from HealthKit", category: AppLogger.sleep)
                syncFromHealthKit()
                setupHealthKitObserver()
            }
        } else {
            AppLogger.info("Sleep sync disabled, stopping HealthKit observer", category: AppLogger.sleep)
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
                AppLogger.error("Sleep observer query error", category: AppLogger.sleep, error: error)
                completionHandler()
                return
            }

            // New sleep data detected - sync from HealthKit
            AppLogger.info("New sleep data detected in HealthKit, syncing", category: AppLogger.sleep)
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
        guard let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: Date()) else {
            AppLogger.logSafetyWarning("Failed to calculate 7 days ago date for average sleep")
            return nil
        }

        let recentEntries = sleepEntries.filter { $0.wakeTime >= sevenDaysAgo }
        guard !recentEntries.isEmpty else { return nil }

        let totalHours = recentEntries.reduce(0.0) { $0 + ($1.duration / 3600) }
        return totalHours / Double(recentEntries.count)
    }

    /// Sleep trend (comparing last 7 days to previous 7 days)
    var sleepTrend: Double? {
        let calendar = Calendar.current
        let today = Date()
        guard let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: today),
              let fourteenDaysAgo = calendar.date(byAdding: .day, value: -14, to: today) else {
            AppLogger.logSafetyWarning("Failed to calculate date range for sleep trend")
            return nil
        }

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
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: Date()) else {
            AppLogger.logSafetyWarning("Failed to calculate yesterday date for last night sleep")
            return nil
        }

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
