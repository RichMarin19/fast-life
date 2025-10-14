import Foundation
import Combine

class MoodManager: ObservableObject {
    @Published var moodEntries: [MoodEntry] = []

    private let userDefaults = UserDefaults.standard
    private let moodEntriesKey = "moodEntries"

    // MARK: - HealthKit Sync Properties (Mindfulness Integration)
    @Published var syncWithHealthKit: Bool = false
    private let syncPreferenceKey = "moodSyncWithHealthKit"
    private let hasCompletedInitialImportKey = "moodHasCompletedInitialImport"

    /// Observer suppression flag to prevent infinite sync loops during manual operations
    private var isSuppressingObserver = false

    /// Observer query for automatic HealthKit sync
    private var observerQuery: Any? // HKObserverQuery type-erased

    init() {
        loadMoodEntries()
        loadSyncPreference()

        // Setup observer if sync is already enabled (app restart scenario)
        if syncWithHealthKit && HealthKitManager.shared.isMindfulnessAuthorized() {
            startObservingHealthKit()
        }
    }

    // MARK: - Add/Update Entry

    func addMoodEntry(moodLevel: Int, energyLevel: Int, notes: String? = nil) {
        // ROADMAP REQUIREMENT: Clamp ranges for mood and energy levels
        // Following Apple input validation best practices
        // Reference: https://developer.apple.com/documentation/foundation/formatter/creating_a_custom_formatter
        let clampedMood = max(1, min(10, moodLevel))
        let clampedEnergy = max(1, min(10, energyLevel))

        if moodLevel != clampedMood {
            AppLogger.warning("Mood level clamped: \(moodLevel) → \(clampedMood)", category: AppLogger.mood)
        }
        if energyLevel != clampedEnergy {
            AppLogger.warning("Energy level clamped: \(energyLevel) → \(clampedEnergy)", category: AppLogger.mood)
        }

        let entry = MoodEntry(moodLevel: clampedMood, energyLevel: clampedEnergy, notes: notes, source: .manual)

        // ROADMAP REQUIREMENT: Add dedupe guards for entries in the same time window
        // Following Apple duplicate detection pattern similar to HealthKit
        // Reference: https://developer.apple.com/documentation/healthkit/about_the_healthkit_framework
        if isDuplicate(entry: entry, timeWindow: 3600) { // 1 hour window
            AppLogger.warning("Prevented duplicate mood entry within 1 hour", category: AppLogger.mood)
            return
        }

        // Industry Standard: All @Published property updates must be on main thread
        DispatchQueue.main.async {
            self.moodEntries.append(entry)

            // Sort by date (most recent first)
            self.moodEntries.sort { $0.date > $1.date }

            self.saveMoodEntries()
        }
        AppLogger.info("Added mood entry: mood=\(clampedMood), energy=\(clampedEnergy)", category: AppLogger.mood)

        // Sync to HealthKit as Mindfulness session with mood metadata
        if syncWithHealthKit && entry.source == .manual {
            // Observer suppression prevents infinite sync loops
            isSuppressingObserver = true

            HealthKitManager.shared.saveMoodAsMindfulness(
                moodLevel: clampedMood,
                energyLevel: clampedEnergy,
                notes: notes,
                date: entry.date
            ) { [weak self] success, error in
                // Re-enable observer after HealthKit write completes
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    self?.isSuppressingObserver = false
                    AppLogger.info("Observer suppression lifted after manual mood entry", category: AppLogger.mood)
                }

                if let error = error {
                    AppLogger.error("Failed to sync mood to HealthKit Mindfulness", category: AppLogger.mood, error: error)
                } else if success {
                    AppLogger.info("Synced mood to HealthKit Mindfulness - mood=\(clampedMood), energy=\(clampedEnergy)", category: AppLogger.mood)
                }
            }
        }
    }

    // MARK: - Validation Methods
    // Following Apple input validation pattern
    // Reference: https://developer.apple.com/documentation/foundation/numberformatter

    /// Check if a potential mood entry would be a duplicate within time window
    /// Following roadmap requirement for dedupe guards
    private func isDuplicate(entry: MoodEntry, timeWindow: TimeInterval) -> Bool {
        return moodEntries.contains { existingEntry in
            abs(entry.date.timeIntervalSince(existingEntry.date)) < timeWindow
        }
    }

    /// Validate if mood entry can be added (public method for UI validation)
    func canAddMoodEntry(at date: Date = Date()) -> Bool {
        let tempEntry = MoodEntry(date: date, moodLevel: 5, energyLevel: 5, notes: nil)
        return !isDuplicate(entry: tempEntry, timeWindow: 3600)
    }

    /// Get time remaining until next mood entry can be added
    func timeUntilNextEntry() -> TimeInterval? {
        guard let latestEntry = moodEntries.first else { return nil }
        let timeSinceLatest = Date().timeIntervalSince(latestEntry.date)
        let timeWindow: TimeInterval = 3600 // 1 hour
        return timeSinceLatest < timeWindow ? timeWindow - timeSinceLatest : nil
    }

    // MARK: - Delete Entry

    func deleteMoodEntry(_ entry: MoodEntry) {
        // Industry Standard: All @Published property updates must be on main thread
        DispatchQueue.main.async {
            self.moodEntries.removeAll { $0.id == entry.id }
            self.saveMoodEntries()
        }
    }

    // MARK: - Statistics

    /// Latest mood entry
    var latestEntry: MoodEntry? {
        moodEntries.first
    }

    /// Average mood level over last 7 days
    var averageMoodLevel: Double? {
        guard !moodEntries.isEmpty else { return nil }

        let calendar = Calendar.current
        guard let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: Date()) else {
            AppLogger.logSafetyWarning("Failed to calculate 7 days ago date for average mood")
            return nil
        }

        let recentEntries = moodEntries.filter { $0.date >= sevenDaysAgo }
        guard !recentEntries.isEmpty else { return nil }

        let totalMood = recentEntries.reduce(0) { $0 + $1.moodLevel }
        return Double(totalMood) / Double(recentEntries.count)
    }

    /// Average energy level over last 7 days
    var averageEnergyLevel: Double? {
        guard !moodEntries.isEmpty else { return nil }

        let calendar = Calendar.current
        guard let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: Date()) else {
            AppLogger.logSafetyWarning("Failed to calculate 7 days ago date for average energy")
            return nil
        }

        let recentEntries = moodEntries.filter { $0.date >= sevenDaysAgo }
        guard !recentEntries.isEmpty else { return nil }

        let totalEnergy = recentEntries.reduce(0) { $0 + $1.energyLevel }
        return Double(totalEnergy) / Double(recentEntries.count)
    }

    /// Today's average mood level
    /// Following Apple HealthKit patterns for daily aggregations
    var todayAverageMood: Double? {
        let todayEntries = todayEntries()
        guard !todayEntries.isEmpty else { return nil }

        let totalMood = todayEntries.reduce(0) { $0 + $1.moodLevel }
        return Double(totalMood) / Double(todayEntries.count)
    }

    /// Today's average energy level
    /// Following Apple HealthKit patterns for daily aggregations
    var todayAverageEnergy: Double? {
        let todayEntries = todayEntries()
        guard !todayEntries.isEmpty else { return nil }

        let totalEnergy = todayEntries.reduce(0) { $0 + $1.energyLevel }
        return Double(totalEnergy) / Double(todayEntries.count)
    }

    /// Get today's mood entries
    /// Following existing HydrationManager.todaysDrinks() pattern for consistency
    private func todayEntries() -> [MoodEntry] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        return moodEntries.filter { entry in
            calendar.isDate(entry.date, inSameDayAs: today)
        }
    }

    /// Get entries for a specific date range
    func entriesForRange(days: Int) -> [MoodEntry] {
        let calendar = Calendar.current
        guard let startDate = calendar.date(byAdding: .day, value: -days, to: Date()) else {
            return []
        }

        return moodEntries.filter { $0.date >= startDate }
    }

    // MARK: - Persistence

    private func saveMoodEntries() {
        if let encoded = try? JSONEncoder().encode(moodEntries) {
            userDefaults.set(encoded, forKey: moodEntriesKey)
        }
    }

    private func loadMoodEntries() {
        guard let data = userDefaults.data(forKey: moodEntriesKey),
              let entries = try? JSONDecoder().decode([MoodEntry].self, from: data) else {
            return
        }
        moodEntries = entries.sorted { $0.date > $1.date }
    }

    // MARK: - Universal HealthKit Sync Architecture (Mindfulness Integration)
    // Following Universal Sync Architecture patterns from handoff.md
    // Revolutionary approach: Sync mood data as HealthKit Mindfulness sessions with custom metadata

    /// Automatic observer-triggered sync (Universal Method #1)
    func syncFromHealthKit(startDate: Date? = nil, completion: ((Int, Error?) -> Void)? = nil) {
        guard syncWithHealthKit else {
            DispatchQueue.main.async {
                completion?(0, nil)
            }
            return
        }

        guard HealthKitManager.shared.isMindfulnessAuthorized() else {
            AppLogger.warning("HealthKit not authorized for mindfulness/mood sync", category: AppLogger.mood)
            DispatchQueue.main.async {
                completion?(0, NSError(domain: "MoodManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "HealthKit not authorized"]))
            }
            return
        }

        // Prevent sync during observer suppression (manual operations)
        guard !isSuppressingObserver else {
            AppLogger.info("Skipping HealthKit mood sync - observer suppressed during manual operation", category: AppLogger.mood)
            DispatchQueue.main.async {
                completion?(0, nil)
            }
            return
        }

        // Default to comprehensive sync (1 year) for mood data consistency
        let fromDate = startDate ?? Calendar.current.date(byAdding: .year, value: -1, to: Date())!

        AppLogger.info("Starting mood sync from HealthKit Mindfulness sessions", category: AppLogger.mood)

        HealthKitManager.shared.fetchMoodFromMindfulness(startDate: fromDate) { [weak self] moodEntries in
            guard let self = self else {
                DispatchQueue.main.async {
                    completion?(0, NSError(domain: "MoodManager", code: 2, userInfo: [NSLocalizedDescriptionKey: "MoodManager deallocated"]))
                }
                return
            }

            // Industry Standard: All @Published property updates must be on main thread (SwiftUI + HealthKit best practice)
            DispatchQueue.main.async {
                // Track newly added entries for accurate reporting
                var newlyAddedCount = 0

                // Import mood data from HealthKit Mindfulness with robust deduplication
                for hkEntry in moodEntries {
                    // Comprehensive duplicate check following WeightManager pattern
                    let isDuplicate = self.moodEntries.contains { entry in
                        abs(entry.date.timeIntervalSince(hkEntry.date)) < 300 && // Within 5 minutes
                        entry.moodLevel == hkEntry.moodLevel &&
                        entry.energyLevel == hkEntry.energyLevel
                    }

                    if !isDuplicate {
                        let entry = MoodEntry(
                            date: hkEntry.date,
                            moodLevel: hkEntry.moodLevel,
                            energyLevel: hkEntry.energyLevel,
                            notes: hkEntry.notes,
                            source: .healthKit
                        )
                        self.moodEntries.append(entry)
                        newlyAddedCount += 1
                    }
                }

                // Sort by date (most recent first) and save
                self.moodEntries.sort { $0.date > $1.date }
                self.saveMoodEntries()

                // Report sync results
                AppLogger.info("HealthKit mood sync completed: \(newlyAddedCount) new mood entries added from Mindfulness", category: AppLogger.mood)
                completion?(newlyAddedCount, nil)
            }
        }
    }

    /// Complete historical data import (Universal Method #2)
    func syncFromHealthKitHistorical(startDate: Date, completion: @escaping (Int, Error?) -> Void) {
        guard syncWithHealthKit else {
            DispatchQueue.main.async {
                completion(0, NSError(domain: "MoodManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "HealthKit sync is disabled"]))
            }
            return
        }

        AppLogger.info("Starting historical mood sync from HealthKit Mindfulness from \(startDate)", category: AppLogger.mood)

        HealthKitManager.shared.fetchMoodFromMindfulness(startDate: startDate) { [weak self] moodEntries in
            guard let self = self else {
                DispatchQueue.main.async {
                    completion(0, NSError(domain: "MoodManager", code: 2, userInfo: [NSLocalizedDescriptionKey: "MoodManager instance deallocated"]))
                }
                return
            }

            // Industry Standard: All @Published property updates must be on main thread (SwiftUI + HealthKit best practice)
            DispatchQueue.main.async {
                // Track newly added entries for accurate reporting
                var newlyAddedCount = 0

                // Merge HealthKit mood entries with local entries using robust deduplication
                for hkEntry in moodEntries {
                    // Historical import uses more flexible duplicate check
                    let isDuplicate = self.moodEntries.contains { entry in
                        abs(entry.date.timeIntervalSince(hkEntry.date)) < 600 && // Within 10 minutes (flexible for historical)
                        entry.moodLevel == hkEntry.moodLevel &&
                        entry.energyLevel == hkEntry.energyLevel
                    }

                    if !isDuplicate {
                        let entry = MoodEntry(
                            date: hkEntry.date,
                            moodLevel: hkEntry.moodLevel,
                            energyLevel: hkEntry.energyLevel,
                            notes: hkEntry.notes,
                            source: .healthKit
                        )
                        self.moodEntries.append(entry)
                        newlyAddedCount += 1
                    }
                }

                // Sort by date (most recent first)
                self.moodEntries.sort { $0.date > $1.date }
                self.saveMoodEntries()

                // Report actual sync results
                AppLogger.info("Historical HealthKit mood sync completed: \(newlyAddedCount) new mood entries imported from \(moodEntries.count) total Mindfulness sessions", category: AppLogger.mood)
                completion(newlyAddedCount, nil)
            }
        }
    }

    /// Manual sync with deletion detection (Universal Method #3)
    func syncFromHealthKitWithReset(startDate: Date, completion: @escaping (Int, Error?) -> Void) {
        guard syncWithHealthKit else {
            DispatchQueue.main.async {
                completion(0, NSError(domain: "MoodManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "HealthKit sync is disabled"]))
            }
            return
        }

        AppLogger.info("Starting manual mood sync with anchor reset for deletion detection from \(startDate)", category: AppLogger.mood)

        HealthKitManager.shared.fetchMoodFromMindfulness(startDate: startDate) { [weak self] moodEntries in
            guard let self = self else {
                DispatchQueue.main.async {
                    completion(0, NSError(domain: "MoodManager", code: 2, userInfo: [NSLocalizedDescriptionKey: "MoodManager instance deallocated"]))
                }
                return
            }

            // Industry Standard: All @Published property updates must be on main thread (SwiftUI + HealthKit best practice)
            DispatchQueue.main.async {
                // Industry Standard: Complete sync with deletion detection
                // Step 1: Remove HealthKit entries that are no longer in Apple Health
                let originalCount = self.moodEntries.count

                self.moodEntries.removeAll { fastLifeEntry in
                    // Only remove HealthKit-sourced entries (preserve manual entries)
                    guard fastLifeEntry.source == .healthKit else {
                        return false
                    }

                    // Check if this Fast LIFe mood entry still exists in current HealthKit data
                    let stillExistsInHealthKit = moodEntries.contains { healthKitEntry in
                        let timeDiff = abs(fastLifeEntry.date.timeIntervalSince(healthKitEntry.date))
                        return timeDiff < 300 && // Within 5 minutes
                               fastLifeEntry.moodLevel == healthKitEntry.moodLevel &&
                               fastLifeEntry.energyLevel == healthKitEntry.energyLevel
                    }

                    return !stillExistsInHealthKit
                }
                let deletedCount = originalCount - self.moodEntries.count

                // Step 2: Add new HealthKit mood entries not already in Fast LIFe
                var addedCount = 0
                for healthKitEntry in moodEntries {
                    let alreadyExists = self.moodEntries.contains { fastLifeEntry in
                        let timeDiff = abs(fastLifeEntry.date.timeIntervalSince(healthKitEntry.date))
                        return timeDiff < 300 &&
                               fastLifeEntry.moodLevel == healthKitEntry.moodLevel &&
                               fastLifeEntry.energyLevel == healthKitEntry.energyLevel
                    }

                    if !alreadyExists {
                        let entry = MoodEntry(
                            date: healthKitEntry.date,
                            moodLevel: healthKitEntry.moodLevel,
                            energyLevel: healthKitEntry.energyLevel,
                            notes: healthKitEntry.notes,
                            source: .healthKit
                        )
                        self.moodEntries.append(entry)
                        addedCount += 1
                    }
                }

                // Sort by date (most recent first) and save
                self.moodEntries.sort { $0.date > $1.date }
                self.saveMoodEntries()

                // Report comprehensive sync results
                AppLogger.info("Manual HealthKit mood sync completed: \(addedCount) entries added, \(deletedCount) entries removed, \(moodEntries.count) total HealthKit Mindfulness entries", category: AppLogger.mood)
                completion(addedCount, nil)
            }
        }
    }

    // MARK: - Observer Pattern Implementation

    /// Start observing HealthKit for automatic mood sync (Universal Pattern)
    func startObservingHealthKit() {
        guard syncWithHealthKit && HealthKitManager.shared.isMindfulnessAuthorized() else {
            AppLogger.info("Mood HealthKit observer not started - sync disabled or not authorized", category: AppLogger.mood)
            return
        }

        // Start observing Mindfulness data changes for mood sync
        HealthKitManager.shared.startObservingMindfulness { [weak self] in
            guard let self = self else { return }

            // Industry Standard: All @Published property updates must be on main thread
            DispatchQueue.main.async {
                // Trigger automatic sync when HealthKit Mindfulness data changes
                self.syncFromHealthKit { count, error in
                    if let error = error {
                        AppLogger.error("Observer-triggered mood sync failed", category: AppLogger.mood, error: error)
                    } else if count > 0 {
                        AppLogger.info("Observer-triggered mood sync: \(count) new mood entries added from Mindfulness", category: AppLogger.mood)
                    }
                }
            }
        }

        AppLogger.info("Mood HealthKit observer started successfully - automatic sync enabled via Mindfulness", category: AppLogger.mood)
    }

    /// Stop observing HealthKit (Universal Pattern)
    func stopObservingHealthKit() {
        HealthKitManager.shared.stopObservingMindfulness()
        observerQuery = nil
        AppLogger.info("Mood HealthKit observer stopped", category: AppLogger.mood)
    }

    // MARK: - Preference Management (Universal Pattern)

    func setSyncPreference(_ enabled: Bool) {
        AppLogger.info("Setting mood sync preference to \(enabled)", category: AppLogger.mood)
        syncWithHealthKit = enabled
        userDefaults.set(enabled, forKey: syncPreferenceKey)

        if enabled {
            // Request Mindfulness authorization for mood sync
            if !HealthKitManager.shared.isMindfulnessAuthorized() {
                HealthKitManager.shared.requestMindfulnessAuthorization { [weak self] success, error in
                    DispatchQueue.main.async {
                        if success {
                            AppLogger.info("Mindfulness authorization granted for mood sync, syncing from HealthKit", category: AppLogger.mood)
                            self?.syncFromHealthKit { _, _ in }
                            self?.startObservingHealthKit()
                        } else {
                            AppLogger.error("Mindfulness authorization failed for mood sync", category: AppLogger.mood, error: error)
                        }
                    }
                }
            } else {
                AppLogger.info("Already authorized for Mindfulness, syncing mood data from HealthKit", category: AppLogger.mood)
                syncFromHealthKit { _, _ in }
                startObservingHealthKit()
            }
        } else {
            AppLogger.info("Mood sync disabled, stopping HealthKit Mindfulness observer", category: AppLogger.mood)
            stopObservingHealthKit()
        }
    }

    private func loadSyncPreference() {
        syncWithHealthKit = userDefaults.bool(forKey: syncPreferenceKey)
    }

    func hasCompletedInitialImport() -> Bool {
        return userDefaults.bool(forKey: hasCompletedInitialImportKey)
    }

    func markInitialImportComplete() {
        userDefaults.set(true, forKey: hasCompletedInitialImportKey)
    }
}
