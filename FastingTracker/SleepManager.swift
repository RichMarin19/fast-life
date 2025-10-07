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
        Log.info("Adding sleep entry", category: .sleep, metadata: ["duration": String(format: "%.1fh", duration), "source": "\(entry.source)"])

        // Validate that wake time is after bed time
        guard entry.wakeTime > entry.bedTime else {
            Log.error("Invalid sleep entry: wake time must be after bed time", category: .sleep)
            return
        }

        sleepEntries.append(entry)

        // Sort by wake time (most recent first)
        sleepEntries.sort { $0.wakeTime > $1.wakeTime }

        saveSleepEntries()

        // Sync to HealthKit if enabled and this is a manual entry
        // NOTE: HealthKit entries (source == .healthKit) are NOT synced back (would create duplicates)
        if syncWithHealthKit && entry.source == .manual {
            Log.debug("Syncing manual sleep entry to HealthKit", category: .sleep)
            HealthKitManager.shared.saveSleep(
                bedTime: entry.bedTime,
                wakeTime: entry.wakeTime,
                completion: { success, error in
                    if success {
                        Log.logSuccess("Sleep synced to HealthKit", category: .sleep)
                    } else {
                        Log.logFailure("Sleep sync to HealthKit", category: .sleep, error: error)
                    }
                }
            )
        } else if !syncWithHealthKit {
            Log.debug("Skipped HealthKit sync (disabled)", category: .sleep)
        } else {
            Log.debug("Skipped HealthKit sync (already from HealthKit)", category: .sleep)
        }

        Log.logSuccess("Sleep entry added to local storage", category: .sleep)
    }

    // MARK: - Delete Sleep Entry

    func deleteSleepEntry(_ entry: SleepEntry) {
        Log.info("Deleting sleep entry", category: .sleep, metadata: ["source": "\(entry.source)"])

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
            Log.debug("Attempting HealthKit deletion", category: .sleep)
            HealthKitManager.shared.deleteSleep(
                bedTime: entry.bedTime,
                wakeTime: entry.wakeTime,
                completion: { success, error in
                    if success {
                        Log.logSuccess("Sleep deleted from HealthKit", category: .sleep)
                    } else {
                        // This is not necessarily an error - entry might not exist in HealthKit
                        // (e.g., if it was added before sync was enabled)
                        Log.debug("HealthKit deletion returned false (may not exist)", category: .sleep)
                    }
                }
            )
        } else {
            Log.debug("Skipped HealthKit deletion (sync disabled)", category: .sleep)
        }

        Log.logSuccess("Sleep entry deleted from local storage", category: .sleep)
    }

    // MARK: - Sync with HealthKit

    func syncFromHealthKit(startDate: Date? = nil) {
        guard syncWithHealthKit else { return }

        // Default to fetching last 30 days if no start date provided
        let start = startDate ?? Calendar.current.date(byAdding: .day, value: -30, to: Date())!

        HealthKitManager.shared.fetchSleepData(startDate: start) { [weak self] healthKitEntries in
            guard let self = self else { return }

            Log.logCount(healthKitEntries.count, action: "Fetched sleep entries from HealthKit", category: .sleep)

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
                Log.logCount(addedCount, action: "Added new sleep entries", category: .sleep)
            }

            // Sort by wake time (most recent first)
            self.sleepEntries.sort { $0.wakeTime > $1.wakeTime }
            self.saveSleepEntries()
        }
    }

    func setSyncPreference(_ enabled: Bool) {
        Log.info("Setting sleep sync preference", category: .sleep, metadata: ["enabled": "\(enabled)"])

        syncWithHealthKit = enabled
        userDefaults.set(enabled, forKey: syncHealthKitKey)

        if enabled {
            // BLOCKER 5 FIX: Request SLEEP authorization only (not all permissions)
            // Per Apple best practices: Request permissions only when needed, per domain
            // Reference: https://developer.apple.com/documentation/healthkit/protecting_user_privacy
            let isAuthorized = HealthKitManager.shared.isSleepAuthorized()
            Log.logAuthResult("Sleep", granted: isAuthorized, category: .sleep)

            if !isAuthorized {
                Log.logAuthRequest("Sleep", category: .sleep)
                HealthKitManager.shared.requestSleepAuthorization { success, error in
                    if success {
                        Log.logSuccess("Sleep authorization granted, syncing from HealthKit", category: .sleep)
                        self.syncFromHealthKit()
                        self.setupHealthKitObserver()
                    } else {
                        Log.logFailure("Sleep authorization", category: .sleep, error: error)
                    }
                }
            } else {
                Log.info("Already authorized, syncing from HealthKit", category: .sleep)
                syncFromHealthKit()
                setupHealthKitObserver()
            }
        } else {
            Log.info("Sleep sync disabled, stopping HealthKit observer", category: .sleep)
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
                Log.error("Sleep observer query error", category: .sleep, error: error)
                completionHandler()
                return
            }

            // New sleep data detected - sync from HealthKit
            Log.info("New sleep data detected in HealthKit, syncing", category: .sleep)
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
