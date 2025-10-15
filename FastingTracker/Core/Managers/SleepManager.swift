import Foundation
import Combine
import HealthKit

@MainActor
class SleepManager: ObservableObject {
    @Published var sleepEntries: [SleepEntry] = []
    @Published var syncWithHealthKit: Bool = true
    @Published var syncMessage: String? = nil

    // MARK: - AppSettings Integration
    // Following Apple single source of truth pattern for global settings
    // Reference: https://developer.apple.com/documentation/swiftui/managing-user-interface-state
    private let appSettings = AppSettings.shared

    private let userDefaults = UserDefaults.standard
    private let sleepEntriesKey = "sleepEntries"
    private let syncHealthKitKey = "syncSleepWithHealthKit"
    private var observerQuery: HKObserverQuery?

    // Industry standard: Suppress observer during manual operations to prevent duplicate sync
    // Following MyFitnessPal, Spotify pattern: Temporary flag during bidirectional operations
    // NOTE: nonisolated for thread-safe access from HealthKit background contexts
    private nonisolated(unsafe) var isSuppressingObserver: Bool = false

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

        // Setup deletion notification observer (Apple standard pattern)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleHealthKitSleepDeletions(_:)),
            name: .healthKitSleepDeleted,
            object: nil
        )
    }

    deinit {
        // Clean up observer when manager is deallocated
        if let query = observerQuery {
            HealthKitManager.shared.stopObservingSleep(query: query)
        }

        // Remove deletion notification observer (Apple standard cleanup)
        NotificationCenter.default.removeObserver(self, name: .healthKitSleepDeleted, object: nil)
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

        // Industry Standard: All @Published property updates must be on main thread
        DispatchQueue.main.async {
            self.sleepEntries.append(entry)

            // Sort by wake time (most recent first)
            self.sleepEntries.sort { $0.wakeTime > $1.wakeTime }

            self.saveSleepEntries()
        }

        // Sync to HealthKit if enabled and this is a manual entry
        if syncWithHealthKit && entry.source == .manual {
            // INDUSTRY STANDARD: Temporarily suppress observer to prevent duplicate sync back
            // Following MyFitnessPal pattern: Manual → HealthKit should not trigger HealthKit → Manual
            isSuppressingObserver = true

            AppLogger.info("Syncing manual sleep entry to HealthKit", category: AppLogger.sleep)
            HealthKitManager.shared.saveSleep(
                bedTime: entry.bedTime,
                wakeTime: entry.wakeTime,
                completion: { [weak self] success, error in
                    // Re-enable observer after a brief delay to ensure HealthKit write completes
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        self?.isSuppressingObserver = false
                        AppLogger.info("Observer suppression lifted after manual sleep sync", category: AppLogger.sleep)
                    }

                    DispatchQueue.main.async {
                        if success {
                            AppLogger.info("Sleep synced to HealthKit", category: AppLogger.sleep)
                            self?.syncMessage = "✅ Sleep synced to Apple Health"
                            // Clear message after 3 seconds
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                                self?.syncMessage = nil
                            }
                        } else {
                            AppLogger.error("Failed to sync sleep to HealthKit", category: AppLogger.sleep, error: error)
                            self?.syncMessage = "❌ Failed to sync to Apple Health"
                            // Clear message after 5 seconds for errors
                            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                                self?.syncMessage = nil
                            }
                        }
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

        // Industry Standard: All @Published property updates must be on main thread
        DispatchQueue.main.async {
            self.sleepEntries.removeAll { $0.id == entry.id }
            self.saveSleepEntries()
        }

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
            // INDUSTRY STANDARD: Suppress observer during HealthKit deletion to prevent sync loop
            // Following MyFitnessPal pattern: Local deletion should not trigger observer re-sync
            isSuppressingObserver = true

            AppLogger.info("Attempting HealthKit deletion with observer suppression", category: AppLogger.sleep)
            HealthKitManager.shared.deleteSleep(
                bedTime: entry.bedTime,
                wakeTime: entry.wakeTime,
                completion: { [weak self] success, error in
                    // Re-enable observer after HealthKit operation completes
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        self?.isSuppressingObserver = false
                        AppLogger.info("Observer suppression lifted after sleep deletion", category: AppLogger.sleep)
                    }

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

        // Default to comprehensive sync (2 years) for data consistency with manual sync
        // Industry Standard: Use same wide date range as manual sync to ensure identical results
        guard let start = startDate ?? Calendar.current.date(byAdding: .year, value: -2, to: Date()) else {
            AppLogger.logSafetyWarning("Failed to calculate 2 years ago date for HealthKit sync")
            return // Cannot sync without valid start date
        }

        HealthKitManager.shared.fetchSleepData(startDate: start, resetAnchor: false) { [weak self] healthKitEntries in
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

            // THREADING FIX: Update @Published properties on main thread
            DispatchQueue.main.async {
                // Sort by wake time (most recent first)
                self.sleepEntries.sort { $0.wakeTime > $1.wakeTime }
                self.saveSleepEntries()
            }
        }
    }

    /// Sync with HealthKit using anchor reset for deletion detection (manual sync)
    /// Following Apple HealthKit Programming Guide: Reset anchor for fresh deletion detection
    /// Used for manual "Sync Now" operations to ensure deletions are detected
    func syncFromHealthKitWithReset(startDate: Date, completion: @escaping (Int, Error?) -> Void) {
        guard syncWithHealthKit else {
            DispatchQueue.main.async {
                completion(0, NSError(domain: "SleepManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "HealthKit sleep sync is disabled"]))
            }
            return
        }

        AppLogger.info("Starting manual sleep sync with anchor reset for deletion detection from \(startDate)", category: AppLogger.sleep)

        HealthKitManager.shared.fetchSleepData(startDate: startDate, resetAnchor: true) { [weak self] healthKitEntries in
            guard let self = self else {
                DispatchQueue.main.async {
                    completion(0, NSError(domain: "SleepManager", code: 2, userInfo: [NSLocalizedDescriptionKey: "SleepManager instance deallocated"]))
                }
                return
            }

            // Industry Standard: Complete sync with deletion detection
            // Prepare sync operations on background thread (read-only operations)

            // Identify entries to remove (ALL entries no longer in Apple Health)
            // Following Weight Tracker breakthrough: Detect ALL deleted entries regardless of source
            // Reasoning: Manual entries are synced TO HealthKit, so they should also be detected when missing
            let entriesToRemove = self.sleepEntries.filter { fastLifeEntry in

                // Check if this Fast LIFe entry still exists in current HealthKit data
                let stillExistsInHealthKit = healthKitEntries.contains { healthKitEntry in
                    abs(fastLifeEntry.bedTime.timeIntervalSince(healthKitEntry.bedTime)) < 60 && // Within 1 minute
                    abs(fastLifeEntry.wakeTime.timeIntervalSince(healthKitEntry.wakeTime)) < 60   // Within 1 minute
                }

                if !stillExistsInHealthKit {
                    AppLogger.info("Will remove deleted sleep entry: \(fastLifeEntry.bedTime) to \(fastLifeEntry.wakeTime)", category: AppLogger.sleep)
                }

                return !stillExistsInHealthKit
            }

            // Identify entries to add (new HealthKit entries not already in Fast LIFe)
            let entriesToAdd = healthKitEntries.filter { healthKitEntry in
                let alreadyExists = self.sleepEntries.contains { fastLifeEntry in
                    abs(fastLifeEntry.bedTime.timeIntervalSince(healthKitEntry.bedTime)) < 60 && // Within 1 minute
                    abs(fastLifeEntry.wakeTime.timeIntervalSince(healthKitEntry.wakeTime)) < 60   // Within 1 minute
                }

                if !alreadyExists {
                    AppLogger.info("Will add new sleep entry: \(healthKitEntry.bedTime) to \(healthKitEntry.wakeTime) with \(healthKitEntry.stages.count) stages", category: AppLogger.sleep)
                }

                return !alreadyExists
            }

            let deletedCount = entriesToRemove.count
            let addedCount = entriesToAdd.count

            // Report comprehensive sync results
            AppLogger.info("Manual HealthKit sleep sync completed: \(addedCount) entries added, \(deletedCount) entries removed, \(healthKitEntries.count) total HealthKit entries", category: AppLogger.sleep)

            // THREADING FIX: Update @Published properties and call completion on main thread
            DispatchQueue.main.async {
                // Step 1: Remove entries that are no longer in HealthKit
                for entryToRemove in entriesToRemove {
                    if let index = self.sleepEntries.firstIndex(where: { $0.id == entryToRemove.id }) {
                        self.sleepEntries.remove(at: index)
                    }
                }

                // Step 2: Add new HealthKit entries
                self.sleepEntries.append(contentsOf: entriesToAdd)

                // Sort by wake time (most recent first) and save
                self.sleepEntries.sort { $0.wakeTime > $1.wakeTime }
                self.saveSleepEntries()
                completion(addedCount, nil)
            }
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

            // INDUSTRY STANDARD: Check if observer is suppressed (manual operation in progress)
            guard let self = self, !self.isSuppressingObserver else {
                AppLogger.info("HealthKit sleep observer suppressed during manual operation - skipping sync", category: AppLogger.sleep)
                completionHandler()
                return
            }

            // New sleep data detected - sync with comprehensive date range for consistency
            // Industry Standard: Use same wide date range as manual sync to ensure identical results
            AppLogger.info("New sleep data detected in HealthKit, syncing with deletion support", category: AppLogger.sleep)
            DispatchQueue.main.async {
                let startDate = Calendar.current.date(byAdding: .year, value: -2, to: Date()) ?? Date()
                self.syncFromHealthKit(startDate: startDate)
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

    // MARK: - Deletion Notification Handler

    @objc private func handleHealthKitSleepDeletions(_ notification: Notification) {
        guard syncWithHealthKit,
              let userInfo = notification.userInfo,
              let deletedSamples = userInfo["deletedSamples"] as? [[String: Any]] else {
            return
        }

        AppLogger.info("Processing \(deletedSamples.count) deleted sleep entries from HealthKit", category: AppLogger.sleep)

        var deletedCount = 0
        for deletedSample in deletedSamples {
            guard let bedTimeValue = deletedSample["bedTime"] as? Date,
                  let wakeTimeValue = deletedSample["wakeTime"] as? Date else {
                continue
            }

            // Find and remove matching sleep entry (time-based matching with 1-minute tolerance)
            if let index = sleepEntries.firstIndex(where: { entry in
                abs(entry.bedTime.timeIntervalSince(bedTimeValue)) < 60 &&
                abs(entry.wakeTime.timeIntervalSince(wakeTimeValue)) < 60
            }) {
                let removedEntry = sleepEntries.remove(at: index)
                deletedCount += 1
                AppLogger.info("Removed sleep entry from HealthKit deletion: \(removedEntry.bedTime) to \(removedEntry.wakeTime)", category: AppLogger.sleep)
            }
        }

        if deletedCount > 0 {
            saveSleepEntries()
            AppLogger.info("Processed \(deletedCount) sleep deletions from HealthKit", category: AppLogger.sleep)
        }
    }
}
