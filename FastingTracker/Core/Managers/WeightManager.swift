import Foundation
import Combine
import HealthKit

@MainActor
class WeightManager: ObservableObject {
    @Published var weightEntries: [WeightEntry] = []
    @Published var syncWithHealthKit: Bool = true
    @Published private(set) var startWeightOverride: Double?
    @Published private(set) var startWeightDate: Date?
    @Published var milestoneCount: Int = 10
    private var futureSyncStartDate: Date?

    // RECOVERY TASK #1: Restore goal weight persistence
    // Following industry standard MVVM pattern - WeightManager owns goal weight persistence
    // Reference: Apple's Data Management in SwiftUI guide
    @Published private(set) var goalWeight: Double = 0

    // MARK: - Dependencies (Protocol-Based for Testability)
    // Phase 2 of MVVM Strategy: Dependency Injection
    // Following Apple's protocol-oriented programming patterns
    private let healthKit: HealthKitManagerProtocol
    private let dataStore: DataStore

    // MARK: - Unit Preference Integration
    // Following Apple single source of truth pattern for global settings
    // Reference: https://developer.apple.com/documentation/swiftui/managing-user-interface-state
    private let appSettings: AppSettings

    // HealthKit sync orchestration
    private let entrySyncCoordinator: WeightEntrySyncCoordinating
    private let analytics: WeightAnalyticsServicing

    // PHASE 2 TASK 2.3: Performance optimization - reusable NumberFormatter
    // Following Apple best practices: NumberFormatter is expensive to create
    // Create once and reuse for all weight formatting operations
    // Reference: Apple Performance Best Practices - Reusing Formatters
    // Thread-safe: NumberFormatter is thread-safe for reading after configuration
    private static let weightFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale.current
        return formatter
    }()

    // Persistence adapter encapsulates ThreadSafeUserDefaults access
    private let persistence: WeightPersistenceManaging
    private var observerQuery: HKObserverQuery?

    // THREAD SAFETY FIX (Task 1A): Replace nonisolated(unsafe) with Actor pattern
    // nonisolated(unsafe) bypasses ALL Swift concurrency safety checks
    // ObserverSuppressionActor provides type-safe synchronization across threads
    private let observerSuppression = ObserverSuppressionActor()

    // MARK: - Initialization

    /// Production init (convenience) - backward compatible
    /// Uses singleton instances for existing code
    convenience init(autoStartSync: Bool = true) {
        self.init(
            healthKit: HealthKitManager.shared,
            dataStore: AppDataStore.shared,
            appSettings: AppSettings.shared,
            entrySyncCoordinator: WeightEntrySyncCoordinator(),
            analytics: WeightAnalyticsService(),
            autoStartSync: autoStartSync
        )
    }

    /// Test init - protocol injection for mocking
    /// Phase 2 of MVVM Strategy: Enable testability
    init(healthKit: HealthKitManagerProtocol,
         dataStore: DataStore,
         appSettings: AppSettings = AppSettings.shared,
         persistence: WeightPersistenceManaging = WeightPersistenceAdapter(),
         entrySyncCoordinator: WeightEntrySyncCoordinating = WeightEntrySyncCoordinator(),
         analytics: WeightAnalyticsServicing = WeightAnalyticsService(),
         autoStartSync: Bool = true) {
        self.healthKit = healthKit
        self.dataStore = dataStore
        self.appSettings = appSettings
        self.persistence = persistence
        self.entrySyncCoordinator = entrySyncCoordinator
        self.analytics = analytics

        loadWeightEntries()
        loadSyncPreference()
        loadStartWeightOverride()
        loadMilestoneCount()
        loadGoalWeight()
        loadFutureSyncStartDate()

        // REMOVED auto-sync on init per Apple HealthKit Best Practices
        // Sync only when user explicitly enables it via setSyncPreference()
        // or when view explicitly calls syncFromHealthKit()
        // Reference: https://developer.apple.com/documentation/healthkit/setting_up_healthkit

        if !autoStartSync {
            if syncWithHealthKit {
                AppLogger.info("Auto-start sync disabled (onboarding reset); clearing stored preference", category: AppLogger.weightTracking)
            }
            syncWithHealthKit = false
            persistence.saveSyncPreference(false)
        } else if syncWithHealthKit && healthKit.isWeightAuthorized() {
            // Setup observer if sync is already enabled (app restart scenario)
            setupHealthKitObserver()
        }

        // Setup deletion notification observer (Apple standard pattern)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleHealthKitWeightDeletions(_:)),
            name: .healthKitWeightDeleted,
            object: nil
        )
    }

    deinit {
        // Clean up observer when manager is deallocated
        if let query = observerQuery {
            healthKit.stopObserving(query: query)
        }

        // Remove deletion notification observer (Apple standard cleanup)
        NotificationCenter.default.removeObserver(self, name: .healthKitWeightDeleted, object: nil)
    }

    // MARK: - Add/Update Weight Entry

    func addWeightEntry(_ entry: WeightEntry) {
        // Industry Standard: All @Published property updates must be on main actor (class already @MainActor)
        let start = Date()
        weightEntries.append(entry)
        weightEntries.sort { $0.date > $1.date }
        saveWeightEntries()
        WeightTrackerMetrics.recordAddEntry(duration: Date().timeIntervalSince(start), source: entry.source)

        // Phase 2a: Cancel today's weight reminder after successful log
        Task {
            await WeightNotificationManager.shared.cancelTodayReminder()
        }

        // Sync to HealthKit if enabled and this is a manual entry
        if syncWithHealthKit && entry.source == .manual {
            // THREAD SAFETY FIX: Use Actor pattern for observer suppression
            // Temporarily suppress observer to prevent duplicate sync back
            Task {
                await observerSuppression.suppressTemporarily(delay: WeightConstants.SyncTiming.observerSuppressionDelay)
            }

            healthKit.saveWeight(weight: entry.weight, bmi: entry.bmi, bodyFat: entry.bodyFat, date: entry.date) { success, error in
                if !success {
                    AppLogger.error("Failed to sync weight to HealthKit", category: AppLogger.weightTracking, error: error)
                } else {
                    AppLogger.info("Manual entry successfully synced to HealthKit", category: AppLogger.weightTracking)
                }
            }
        }
    }

    // MARK: - Delete Weight Entry

    func deleteWeightEntry(_ entry: WeightEntry) {
        let start = Date()
        weightEntries.removeAll { $0.id == entry.id }
        saveWeightEntries()
        WeightTrackerMetrics.recordDeleteEntry(duration: Date().timeIntervalSince(start), source: entry.source)

        // BIDIRECTIONAL DELETION: Delete from HealthKit for ANY entry when sync is enabled
        // Following Apple HealthKit best practices: Use UUID-based deletion for precision
        // Reference: Apple HealthKit Programming Guide - precise sample deletion
        if syncWithHealthKit {
            AppLogger.info("Bidirectional deletion: removing weight entry from HealthKit (source: \(entry.source))", category: AppLogger.weightTracking)

            if let healthKitUUID = entry.healthKitUUID {
                // PRECISE DELETION: Use UUID for exact sample targeting (Apple best practice)
                healthKit.deleteWeightByUUID(healthKitUUID) { success, error in
                    if !success {
                        AppLogger.error("Failed to delete HealthKit sample by UUID during bidirectional sync", category: AppLogger.weightTracking, error: error)
                        // Record precise deletion failure for production debugging
                        if let error = error {
                            CrashReportManager.shared.recordWeightError(error, context: [
                                "operation": "preciseUUIDBidirectionalDeletion",
                                "entrySource": entry.source.rawValue,
                                "healthKitUUID": healthKitUUID.uuidString,
                                "entryDate": entry.date.description
                            ])
                        }
                    } else {
                        AppLogger.info("Successfully deleted HealthKit sample by UUID via bidirectional sync", category: AppLogger.weightTracking)
                    }
                }
            } else {
                // MODERN APPROACH: Find UUID by querying HealthKit, then use precise deletion
                // This replaces deprecated date-based deletion with proper UUID-based approach
                AppLogger.info("No stored UUID - querying HealthKit to find sample for precise deletion", category: AppLogger.weightTracking)

                // Query HealthKit to find the exact sample by date/weight match
                healthKit.findWeightSampleUUID(date: entry.date, weight: entry.weight) { [weak self] uuid in
                    if let foundUUID = uuid {
                        AppLogger.info("Found HealthKit UUID via query - proceeding with precise deletion", category: AppLogger.weightTracking)
                        self?.healthKit.deleteWeightByUUID(foundUUID) { success, error in
                            if !success {
                                AppLogger.error("Failed to delete HealthKit sample by queried UUID", category: AppLogger.weightTracking, error: error)
                            } else {
                                AppLogger.info("Successfully deleted HealthKit sample using queried UUID", category: AppLogger.weightTracking)
                            }
                        }
                    } else {
                        AppLogger.warning("Could not find matching HealthKit sample for deletion", category: AppLogger.weightTracking)
                        // Entry may have been manually deleted from HealthKit already, or never synced
                    }
                }
            }
        }
    }

    // MARK: - Delete All Weight Data

    /// Delete all weight data from Fast LIFe
    /// Used for debugging and troubleshooting HealthKit sync issues
    /// Following Apple HIG: Destructive actions require confirmation (handled in View layer)
    func deleteAllWeightData() {
        AppLogger.info("Deleting all weight data - count before: \(weightEntries.count)", category: AppLogger.weightTracking)

        // Industry Standard: All @Published property updates must be on main thread
        DispatchQueue.main.async {
            self.weightEntries.removeAll()
            self.saveWeightEntries()
            AppLogger.info("Deleted all weight data - count after: \(self.weightEntries.count)", category: AppLogger.weightTracking)
        }
    }

    // MARK: - Unit Conversion Methods
    // Following Apple adapter pattern to maintain backward compatibility
    // Reference: https://docs.swift.org/swift-book/LanguageGuide/Protocols.html#ID521

    /// Convert weight entry to user's preferred unit for display
    /// Maintains backward compatibility while supporting unit preferences
    func displayWeight(for entry: WeightEntry) -> Double {
        return appSettings.weightUnit.fromPounds(entry.weight)
    }

    /// Convert a raw weight value (stored in pounds) to the user's preferred display unit
    /// Used by charts/stats displaying values or deltas in the user's unit
    func displayWeightValue(_ pounds: Double) -> Double {
        appSettings.weightUnit.fromPounds(pounds)
    }

    /// Convert user input from preferred unit to internal pounds
    /// Ensures data consistency in storage format
    func convertToInternalUnit(_ value: Double) -> Double {
        return appSettings.weightUnit.toPounds(value)
    }

    /// Get current weight unit abbreviation for display
    var currentUnitAbbreviation: String {
        return appSettings.weightUnit.abbreviation
    }

    /// Get current weight unit display name
    var currentUnitDisplayName: String {
        return appSettings.weightUnit.displayName
    }

    /// Convert weight value from pounds to display unit
    /// Helper method for UI components that need to display weights
    func convertWeightToDisplayUnit(_ weightInPounds: Double) -> Double {
        return appSettings.weightUnit.fromPounds(weightInPounds)
    }

    /// Format a weight value (stored internally as pounds) for display in the user's preferred unit.
    /// PHASE 2 TASK 2.3: Optimized to reuse static NumberFormatter for performance.
    /// Following Apple best practices: NumberFormatter is expensive to create (~100x slower than reuse).
    /// - Parameters:
    ///   - weightInPounds: The internal weight (pounds).
    ///   - maximumFractionDigits: Max decimals to display (default: 1).
    /// - Returns: Localized weight string (e.g., "150", "68.3 kg").
    func formattedDisplayWeight(_ weightInPounds: Double, maximumFractionDigits: Int = 1) -> String {
        let displayValue = convertWeightToDisplayUnit(weightInPounds)

        // Reuse static formatter (configured once at class load)
        // Only update dynamic properties (fraction digits change per call)
        WeightManager.weightFormatter.locale = Locale(identifier: appSettings.localeIdentifier)
        WeightManager.weightFormatter.maximumFractionDigits = maximumFractionDigits
        WeightManager.weightFormatter.minimumFractionDigits = displayValue.truncatingRemainder(dividingBy: 1).isZero ? 0 : min(1, maximumFractionDigits)

        let number = NSNumber(value: displayValue)
        return WeightManager.weightFormatter.string(from: number) ?? String(format: "%.\(maximumFractionDigits)f", displayValue)
    }

    /// Calculate progress percentage toward a goal weight using the authoritative baseline.
    /// Returns nil when baseline/goal are missing or when progress shouldn't be visualised yet.
    func progressPercentage(toward goalWeight: Double) -> Double? {
        guard goalWeight > 0,
              let startingWeight = resolvedStartWeight()?.weight,
              let currentWeight = latestWeight?.weight else {
            return nil
        }

        let totalWeightToLose = startingWeight - goalWeight
        let weightLostSoFar = startingWeight - currentWeight

        guard totalWeightToLose > 0 else {
            return nil
        }

        if weightLostSoFar <= 0 {
#if DEBUG
            AppLogger.debug(
                """
                Progress percentage clamped to 0 – start: \(startingWeight), current: \(currentWeight), goal: \(goalWeight), lost: \(weightLostSoFar), totalToLose: \(totalWeightToLose)
                """,
                category: AppLogger.weightTracking
            )
#endif
            return 0.0
        }

        let percentage = (weightLostSoFar / totalWeightToLose) * 100.0
        return min(percentage, 100.0)
    }

    /// Returns whichever start weight should be considered authoritative.
    /// Prefers the user override, otherwise falls back to the earliest entry.
    func resolvedStartWeight() -> WeightEntry? {
        if let override = startWeightOverride {
            return WeightEntry(
                id: UUID(),
                date: startWeightDate ?? Date(),
                weight: override,
                source: .manual,
                sourceName: "Fast LIFe"
            )
        }
        return weightEntries.last
    }

    /// Add weight entry from user input in preferred unit
    /// Following Apple data conversion pattern for user input
    /// Reference: https://developer.apple.com/documentation/foundation/measurement
    func addWeightEntryInPreferredUnit(weight: Double, bmi: Double? = nil, bodyFat: Double? = nil, date: Date = Date()) {
        let weightInPounds = appSettings.weightUnit.toPounds(weight)

        // Following roadmap requirement: "ensure edits do not create duplicates"
        // FIXED: Check across ALL sources, not just manual (Industry standard pattern)
        let isDuplicate = weightEntries.contains { entry in
            let withinTimeWindow = abs(entry.date.timeIntervalSince(date)) < WeightConstants.DuplicationThreshold.timeInterval
            let sameWeight = isWeightWithinDuplicateThreshold(
                existingWeight: entry.weight,
                newWeight: weightInPounds,
                threshold: WeightConstants.DuplicationThreshold.weightDelta
            )
            return withinTimeWindow && sameWeight
        }

        guard !isDuplicate else {
            AppLogger.warning("Prevented duplicate weight entry within 30 minutes", category: AppLogger.weightTracking)
            return
        }

        AppLogger.info("Adding weight entry", category: AppLogger.weightTracking)

        // Task 1F Enhancement 4: Manual entries show "Fast LIFe" as source name
        let entry = WeightEntry(
            date: date,
            weight: weightInPounds,
            bmi: bmi,
            bodyFat: bodyFat,
            source: .manual,
            sourceName: "Fast LIFe"
        )
        addWeightEntry(entry)
    }

    /// Check if a potential weight entry would be a duplicate
    /// Following Apple validation pattern for user input
    /// Reference: https://developer.apple.com/documentation/foundation/formatter/creating_a_custom_formatter
    func wouldCreateDuplicate(weight: Double, date: Date = Date()) -> Bool {
        let weightInPounds = appSettings.weightUnit.toPounds(weight)
        return weightEntries.contains { entry in
            let withinTimeWindow = abs(entry.date.timeIntervalSince(date)) < WeightConstants.DuplicationThreshold.timeInterval
            let sameWeight = isWeightWithinDuplicateThreshold(
                existingWeight: entry.weight,
                newWeight: weightInPounds,
                threshold: WeightConstants.DuplicationThreshold.weightDelta
            )
            return withinTimeWindow && sameWeight
        }
    }

    // MARK: - Sync with HealthKit

    func syncFromHealthKit(startDate: Date? = nil, completion: ((Int, Error?) -> Void)? = nil) {
        guard syncWithHealthKit else {
            completion?(0, NSError(domain: "WeightManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "HealthKit sync is disabled"]))
            return
        }

        // Default to comprehensive sync (10 years) for data consistency with manual sync
        // Industry Standard: Use same wide date range as manual sync to ensure identical results
        // PHASE 1 FIX (Task 1.1): Defensive date calculation - Calendar.date() can return nil
        let start: Date
        if let providedStart = startDate {
            start = providedStart
        } else if let calculatedStart = Calendar.current.date(byAdding: .year, value: -WeightConstants.SyncTiming.defaultHistoricalLookbackYears, to: Date()) {
            start = calculatedStart
        } else {
            // Fallback: If Calendar calculation fails (rare), use current date
            AppLogger.error("❌ Calendar date calculation failed in syncFromHealthKit - using Date() as fallback", category: AppLogger.weightTracking)
            start = Date()
        }

        let syncStart = Date()
        healthKit.fetchWeightData(startDate: start, endDate: Date(), resetAnchor: false) { [weak self] healthKitEntries in
            guard let self = self else {
                WeightTrackerMetrics.recordSync(result: .init(type: "incremental", duration: Date().timeIntervalSince(syncStart), success: false))
                completion?(0, NSError(domain: "WeightManager", code: 2, userInfo: [NSLocalizedDescriptionKey: "WeightManager instance deallocated"]))
                return
            }

            // Industry Standard: All @Published property updates must be on main thread (SwiftUI + HealthKit best practice)
            DispatchQueue.main.async {
                let filteredEntries = self.entriesRespectingFutureOnlyCutoff(healthKitEntries)
                let added = self.entrySyncCoordinator.mergeNewEntries(
                    currentEntries: &self.weightEntries,
                    healthKitEntries: filteredEntries,
                    duplicateChecker: self.makeDuplicateChecker(
                        timeThreshold: WeightConstants.DuplicationThreshold.tightTimeInterval,
                        weightThreshold: WeightConstants.DuplicationThreshold.weightDelta
                    )
                )
                self.saveWeightEntries()

                // Report actual sync results
                AppLogger.info("HealthKit sync completed: \(added) new weight entries added", category: AppLogger.weightTracking)
                WeightTrackerMetrics.recordSync(result: .init(type: "incremental", duration: Date().timeIntervalSince(syncStart), success: true))
                completion?(added, nil)
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

        let historicalDays = Calendar.current.dateComponents([.day], from: startDate, to: Date()).day ?? 0
        AppLogger.info("Starting historical weight sync — startDaysAgo=\(historicalDays)", category: AppLogger.weightTracking)

        let syncStart = Date()
        healthKit.fetchWeightDataHistorical(startDate: startDate) { [weak self] healthKitEntries in
            guard let self = self else {
                WeightTrackerMetrics.recordSync(result: .init(type: "historical", duration: Date().timeIntervalSince(syncStart), success: false))
                completion(0, NSError(domain: "WeightManager", code: 2, userInfo: [NSLocalizedDescriptionKey: "WeightManager instance deallocated"]))
                return
            }

            // Industry Standard: All @Published property updates must be on main thread (SwiftUI + HealthKit best practice)
            DispatchQueue.main.async {
                let added = self.entrySyncCoordinator.mergeHistoricalEntries(
                    currentEntries: &self.weightEntries,
                    healthKitEntries: healthKitEntries,
                    duplicateChecker: self.makeDuplicateChecker(
                        timeThreshold: WeightConstants.DuplicationThreshold.historicalTimeInterval,
                        weightThreshold: WeightConstants.DuplicationThreshold.historicalWeightDelta
                    )
                )
                self.saveWeightEntries()

                // Report actual sync results
                AppLogger.info("Historical HealthKit sync completed: \(added) new weight entries imported from \(healthKitEntries.count) total entries", category: AppLogger.weightTracking)

                WeightTrackerMetrics.recordSync(result: .init(type: "historical", duration: Date().timeIntervalSince(syncStart), success: true))
                completion(added, nil)
            }
        }
    }

    /// Sync with HealthKit using anchor reset for deletion detection (manual sync)
    /// Following Apple HealthKit Programming Guide: Reset anchor for fresh deletion detection
    /// Used for manual "Sync Now" operations to ensure deletions are detected
    func syncFromHealthKitWithReset(startDate: Date, completion: @escaping (Int, Error?) -> Void) {
        guard syncWithHealthKit else {
            completion(0, NSError(domain: "WeightManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "HealthKit sync is disabled"]))
            return
        }

        let manualSyncDays = Calendar.current.dateComponents([.day], from: startDate, to: Date()).day ?? 0
        AppLogger.info("Starting manual sync with anchor reset for deletion detection — startDaysAgo=\(manualSyncDays)", category: AppLogger.weightTracking)

        let syncStart = Date()
        healthKit.fetchWeightData(startDate: startDate, endDate: Date(), resetAnchor: true) { [weak self] healthKitEntries in
            guard let self = self else {
                WeightTrackerMetrics.recordSync(result: .init(type: "manual_reset", duration: Date().timeIntervalSince(syncStart), success: false))
                completion(0, NSError(domain: "WeightManager", code: 2, userInfo: [NSLocalizedDescriptionKey: "WeightManager instance deallocated"]))
                return
            }

            // Industry Standard: All @Published property updates must be on main thread (SwiftUI + HealthKit best practice)
            DispatchQueue.main.async {
                let result = self.entrySyncCoordinator.reconcileAfterReset(
                    currentEntries: &self.weightEntries,
                    healthKitEntries: healthKitEntries,
                    duplicateChecker: self.makeDuplicateChecker(
                        timeThreshold: WeightConstants.DuplicationThreshold.tightTimeInterval,
                        weightThreshold: WeightConstants.DuplicationThreshold.weightDelta
                    )
                )
                self.saveWeightEntries()

                // Report comprehensive sync results
                AppLogger.info("Manual HealthKit sync completed: \(result.added) entries added, \(result.deleted) entries removed, \(healthKitEntries.count) total HealthKit entries", category: AppLogger.weightTracking)

                WeightTrackerMetrics.recordSync(result: .init(type: "manual_reset", duration: Date().timeIntervalSince(syncStart), success: true))
                completion(result.added, nil)
            }
        }
    }

    private func entriesRespectingFutureOnlyCutoff(_ entries: [WeightEntry]) -> [WeightEntry] {
        guard let cutoff = futureSyncStartDate else { return entries }
        let filtered = entries.filter { $0.date >= cutoff }
        if filtered.count != entries.count {
            AppLogger.info("Future-only sync filter dropped \(entries.count - filtered.count) entries older than \(cutoff)", category: AppLogger.weightTracking)
        }
        return filtered
    }

    func setSyncPreference(_ enabled: Bool) {
        AppLogger.info("Setting weight sync preference to \(enabled)", category: AppLogger.weightTracking)

        syncWithHealthKit = enabled
        persistence.saveSyncPreference(enabled)

        if enabled {
            // BLOCKER 5 FIX: Request WEIGHT authorization only (not all permissions)
            // Per Apple best practices: Request permissions only when needed, per domain
            // Reference: https://developer.apple.com/documentation/healthkit/protecting_user_privacy
            let isAuthorized = healthKit.isWeightAuthorized()
            AppLogger.info("Weight-specific HealthKit authorization status: \(isAuthorized ? "granted" : "denied")", category: AppLogger.weightTracking)

            if !isAuthorized {
                AppLogger.info("Requesting weight-specific HealthKit authorization", category: AppLogger.weightTracking)
                healthKit.requestWeightAuthorization { success, error in
                    if success {
                        AppLogger.info("Weight-specific HealthKit authorization granted, setting up observer", category: AppLogger.weightTracking)
                        // INDUSTRY STANDARD FIX: Don't trigger sync from Model layer
                        // Let the View layer (WeightSettingsView) handle sync and dialog logic
                        // Following MVC pattern: Model sets up infrastructure, View controls user interactions
                        self.setupHealthKitObserver()
                    } else {
                        AppLogger.error("Weight-specific HealthKit authorization failed", category: AppLogger.weightTracking, error: error)
                        // Record authorization failure for production debugging
                        if let error = error {
                            CrashReportManager.shared.recordWeightError(error, context: [
                                "operation": "requestWeightAuthorization"
                            ])
                        }
                    }
                }
            } else {
                AppLogger.info("Already authorized, setting up observer", category: AppLogger.weightTracking)
                // INDUSTRY STANDARD FIX: Don't trigger sync from Model layer
                // Let the View layer (WeightSettingsView) handle sync and dialog logic
                // Following MVC pattern: Model sets up infrastructure, View controls user interactions
                setupHealthKitObserver()
            }
        } else {
            AppLogger.info("Weight sync disabled, stopping HealthKit observer", category: AppLogger.weightTracking)
            // Stop observing when sync is disabled
            if let query = observerQuery {
                healthKit.stopObserving(query: query)
                observerQuery = nil
            }
            updateFutureSyncStartDate(nil)
        }
    }

    /// Used when onboarding restarts so we don't auto-sync until the user opts in again.
    func disableSyncForOnboardingReset() {
        guard syncWithHealthKit else {
            AppLogger.info("Onboarding reset requested; sync already disabled", category: AppLogger.weightTracking)
            persistence.saveSyncPreference(false)
            updateFutureSyncStartDate(nil)
            return
        }

        AppLogger.info("Onboarding reset requested; forcing HealthKit sync off until user opts in", category: AppLogger.weightTracking)
        setSyncPreference(false)
        updateFutureSyncStartDate(nil)
    }

    /// Seeds the HealthKit anchor so future-only sync starts from "now" and then enables ongoing sync.
    func enableFutureOnlySync(completion: (() -> Void)? = nil) {
        let now = Date()
        AppLogger.info("Preparing future-only sync starting at \(now)", category: AppLogger.weightTracking)
        updateFutureSyncStartDate(now)
        healthKit.seedWeightAnchor(at: now) { [weak self] in
            guard let self else {
                completion?()
                return
            }
            Task { @MainActor in
                self.setSyncPreference(true)
                completion?()
            }
        }
    }

    func resetFutureOnlySyncCutoff() {
        updateFutureSyncStartDate(nil)
    }

    // MARK: - HealthKit Observer

    private func setupHealthKitObserver() {
        // Only setup observer if sync is enabled and specifically authorized for weight data
        // Following Apple HealthKit best practices: observers need specific data type authorization
        guard syncWithHealthKit && healthKit.isWeightAuthorized() else {
            AppLogger.info("Weight observer not set up - sync disabled or not authorized for weight data", category: AppLogger.weightTracking)
            return
        }

        // Remove existing observer if any
        if let existingQuery = observerQuery {
            healthKit.stopObserving(query: existingQuery)
        }

        // Create observer query for weight data
        guard let weightType = HKObjectType.quantityType(forIdentifier: .bodyMass) else { return }

        let query = HKObserverQuery(sampleType: weightType, predicate: nil) { [weak self] _, completionHandler, error in
            if let error = error {
                AppLogger.error("Weight observer query error", category: AppLogger.weightTracking, error: error)
                completionHandler()
                return
            }

            guard let self = self else {
                completionHandler()
                return
            }

            // THREAD SAFETY FIX: Check observer suppression using Actor pattern
            // Actor provides thread-safe access from HealthKit background callback
            Task {
                let suppressed = await self.observerSuppression.isSuppressed()
                guard !suppressed else {
                    AppLogger.info("HealthKit observer suppressed during manual operation - skipping sync", category: AppLogger.weightTracking)
                    completionHandler()
                    return
                }

                // New weight data detected - sync with comprehensive date range
                AppLogger.info("New weight data detected in HealthKit, syncing with deletion support", category: AppLogger.weightTracking)
                await MainActor.run {
                    let startDate = Calendar.current.date(byAdding: .year, value: -WeightConstants.SyncTiming.defaultHistoricalLookbackYears, to: Date()) ?? Date()
                    self.syncFromHealthKit(startDate: startDate, completion: nil)
                }

                // Must call completion handler
                completionHandler()
            }
        }

        observerQuery = query
        healthKit.startObserving(query: query)
        AppLogger.info("Weight HealthKit observer started successfully - automatic sync enabled", category: AppLogger.weightTracking)
    }

    // MARK: - Statistics

    var latestWeight: WeightEntry? {
        weightEntries.first
    }

    var weightTrend: Double? {
        analytics.weightTrend(for: weightEntries)
    }

    var averageWeight: Double? {
        analytics.averageWeight(for: weightEntries)
    }

    func weightChange(since date: Date) -> Double? {
        analytics.weightChange(
            for: weightEntries,
            latestEntry: latestWeight,
            since: date,
            hasStartWeightOverride: startWeightOverride != nil
        )
    }

    // MARK: - Milestone Computation (Task 1E Phase 3)
    // Industry Pattern: Goal-based milestone tracking for long-term weight loss
    // Reference: Apple Health, MyFitnessPal milestone systems

    /// Start weight - first (oldest) weight entry
    /// Used as baseline for milestone calculations
    var startWeight: WeightEntry? {
        resolvedStartWeight()
    }

    /// Total weight change from start to current
    /// Returns nil if insufficient data (need at least 2 entries)
    var totalWeightChange: Double? {
        analytics.totalWeightChange(
            startWeight: resolvedStartWeight()?.weight,
            currentWeight: latestWeight?.weight,
            entryCount: weightEntries.count,
            hasStartWeightOverride: startWeightOverride != nil
        )
    }

    /// Calculate progress toward goal weight (0.0 to 1.0)
    /// - Parameter goalWeight: Target weight in pounds (internal unit)
    /// - Returns: Progress as decimal (0.0 = no progress, 1.0 = goal reached)
    /// Returns nil if insufficient data or invalid goal
    func progressToGoal(goalWeight: Double) -> Double? {
        analytics.progressToGoal(
            startWeight: resolvedStartWeight()?.weight,
            currentWeight: latestWeight?.weight,
            goalWeight: goalWeight
        )
    }

    /// Calculate current milestone index (1-10)
    /// Divides weight loss journey into 10 equal milestones
    /// - Parameter goalWeight: Target weight in pounds (internal unit)
    /// - Returns: Current milestone number (1-10), or 1 if insufficient data
    func currentMilestoneIndex(goalWeight: Double, totalMilestones: Int = 10) -> Int {
        let progress = progressToGoal(goalWeight: goalWeight)
        return analytics.currentMilestoneIndex(progress: progress, totalMilestones: totalMilestones)
    }

    /// Calculate number of completed milestones (0-10)
    /// Completed means fully passed (100% of that milestone segment)
    /// - Parameter goalWeight: Target weight in pounds (internal unit)
    /// - Returns: Count of fully completed milestones (0-10)
    func completedMilestones(goalWeight: Double, totalMilestones: Int = 10) -> Int {
        let progress = progressToGoal(goalWeight: goalWeight)
        return analytics.completedMilestones(progress: progress, totalMilestones: totalMilestones)
    }

    /// Calculate progress within current milestone (0.0 to 1.0)
    /// Shows how far along within the current milestone segment
    /// - Parameter goalWeight: Target weight in pounds (internal unit)
    /// - Returns: Progress within current milestone (0.0-1.0), or 0.0 if insufficient data
    func milestoneProgress(goalWeight: Double, totalMilestones: Int = 10) -> Double {
        let progress = progressToGoal(goalWeight: goalWeight)
        return analytics.milestoneProgress(progress: progress, totalMilestones: totalMilestones)
    }

    /// Get milestone statistics for display
    /// Convenience method that returns all milestone-related data
    /// - Parameter goalWeight: Target weight in pounds (internal unit)
    /// - Returns: Tuple with all milestone stats, or nil if insufficient data
    func milestoneStats(goalWeight: Double, totalMilestones: Int = 10) -> (
        currentIndex: Int,
        completed: Int,
        progress: Double,
        startWeight: Double,
        currentWeight: Double,
        remainingWeight: Double
    )? {
        let progress = progressToGoal(goalWeight: goalWeight)
        guard let stats = analytics.milestoneStats(
            startWeight: resolvedStartWeight()?.weight,
            currentWeight: latestWeight?.weight,
            goalWeight: goalWeight,
            totalMilestones: totalMilestones,
            progress: progress,
            entryCount: weightEntries.count,
            hasStartWeightOverride: startWeightOverride != nil
        ) else {
            return nil
        }

        return (
            currentIndex: stats.currentIndex,
            completed: stats.completedCount,
            progress: stats.currentMilestoneProgress,
            startWeight: stats.startWeight,
            currentWeight: stats.currentWeight,
            remainingWeight: stats.remainingWeight
        )
    }

    // MARK: - Weight History Filtering (Task 1F + Enhancement 3)
    // Industry Pattern: Time range filtering for performance optimization
    // Reference: Apple Health, Spotify - default to recent data with expandable ranges

    /// Filter weight entries by time range for Weight History card
    /// Optimizes performance by loading only entries within selected range
    /// - Parameters:
    ///   - range: Time range to filter by (1 day, 7 days, 30 days, etc.)
    ///   - customStartDate: Custom start date (only used when range is .custom)
    ///   - customEndDate: Custom end date (only used when range is .custom) - Task 1F Enhancement 3
    /// - Returns: Filtered weight entries within the specified time range
    func weightEntries(for range: WeightHistoryTimeRange, customStartDate: Date? = nil, customEndDate: Date? = nil) -> [WeightEntry] {
        let now = Date()
        let calendar = Calendar.current

        // Calculate start and end dates based on time range
        let startDate: Date?
        let endDate: Date

        if range == .custom {
            // Task 1F Enhancement 3: Use provided custom start AND end dates
            startDate = customStartDate
            endDate = customEndDate ?? now  // Default to now if no end date provided
        } else if range == .allTime {
            // Return all entries (no filtering)
            return weightEntries
        } else {
            // Use dateComponents from enum for calculation
            if let components = range.dateComponents {
                startDate = calendar.date(byAdding: components.component, value: components.value, to: now)
            } else {
                // Fallback: return all entries if calculation fails
                return weightEntries
            }
            endDate = now  // End date is always "now" for preset ranges
        }

        // Filter entries by start date
        guard let start = startDate else {
            return weightEntries  // Return all if no valid start date
        }

        // Task 1F Enhancement 3: Filter entries BETWEEN start and end dates (inclusive)
        // Industry Pattern: Date range filtering with both bounds
        // Reference: Apple Calendar, Banking Apps, Google Analytics
        return weightEntries.filter { entry in
            entry.date >= start && entry.date <= endDate
        }
    }

    // MARK: - Persistence

    private func saveWeightEntries() {
        persistence.saveWeightEntries(weightEntries)
    }

    private func makeDuplicateChecker(timeThreshold: TimeInterval,
                                      weightThreshold: Double) -> (WeightEntry, WeightEntry) -> Bool {
        { existing, newEntry in
            self.isDuplicateEntry(
                existing: existing,
                newEntry: newEntry,
                timeThreshold: timeThreshold,
                weightThreshold: weightThreshold
            )
        }
    }

    private func isWeightWithinDuplicateThreshold(existingWeight: Double,
                                                  newWeight: Double,
                                                  threshold: Double) -> Bool {
        let epsilon = 0.00001
        let adjustedThreshold = max(0, threshold - epsilon)
        return abs(existingWeight - newWeight) < adjustedThreshold
    }

    private func isDuplicateEntry(existing: WeightEntry,
                                  newEntry: WeightEntry,
                                  timeThreshold: TimeInterval,
                                  weightThreshold: Double) -> Bool {
        let timeDiff = abs(existing.date.timeIntervalSince(newEntry.date))
        guard timeDiff < timeThreshold else { return false }
        return isWeightWithinDuplicateThreshold(existingWeight: existing.weight,
                                                newWeight: newEntry.weight,
                                                threshold: weightThreshold)
    }

    private func loadWeightEntries() {
        weightEntries = persistence.loadWeightEntries()
    }

    private func loadSyncPreference() {
        if let stored = persistence.loadSyncPreference() {
            syncWithHealthKit = stored
        }
    }

    private func loadStartWeightOverride() {
        let stored = persistence.loadStartWeightOverride()
        startWeightOverride = stored.weight
        startWeightDate = stored.date
    }

    private func loadMilestoneCount() {
        if let stored = persistence.loadMilestoneCount() {
            milestoneCount = sanitizedMilestoneCount(stored)
        } else {
            milestoneCount = 10
        }
    }

    // PHASE 1 FIX (Task 1.4): Defensive logging - alert when values are clamped
    private func sanitizedMilestoneCount(_ value: Int) -> Int {
        let sanitized = max(0, min(10, value))
        if sanitized != value {
            AppLogger.warning("⚠️ Milestone count clamped from \(value) to \(sanitized) (valid range: 0-10)", category: AppLogger.weightTracking)
        }
        return sanitized
    }

    // RECOVERY TASK #1: Load goal weight from persistent storage
    private func loadGoalWeight() {
        if let stored = persistence.loadGoalWeight() {
            goalWeight = stored
            AppLogger.info("Loaded goal weight — hasValue=\(stored > 0)", category: AppLogger.weightTracking)
        } else {
            goalWeight = 0
            AppLogger.info("No stored goal weight found, defaulting to 0", category: AppLogger.weightTracking)
        }
    }

    private func updateFutureSyncStartDate(_ date: Date?) {
        futureSyncStartDate = date
        persistence.saveFutureSyncStartDate(date)
    }

    private func loadFutureSyncStartDate() {
        futureSyncStartDate = persistence.loadFutureSyncStartDate()
        if let cutoff = futureSyncStartDate {
            AppLogger.info("Loaded future-only sync cutoff at \(cutoff)", category: AppLogger.weightTracking)
        }
    }

    // RECOVERY TASK #1: Set goal weight with persistence
    // Following industry standard MVVM pattern - Manager owns persistence
    // View layer updates binding, Manager handles UserDefaults
    // Reference: Apple's Data Management in SwiftUI guide
    func setGoalWeight(_ weight: Double) {
        let previousGoal = goalWeight
        goalWeight = weight
        persistence.saveGoalWeight(weight)

        let direction: String
        if previousGoal == 0 {
            direction = "initial-set"
        } else if weight < previousGoal {
            direction = "decrease"
        } else if weight > previousGoal {
            direction = "increase"
        } else {
            direction = "unchanged"
        }

        AppLogger.info("Goal weight updated — direction=\(direction)", category: AppLogger.weightTracking)
    }

    func setStartWeightOverride(_ displayWeight: Double?, date: Date?, unit: WeightUnit? = nil) {
        if let weight = displayWeight, weight > 0 {
            let internalValue: Double
            if let unit {
                internalValue = unit.toPounds(weight)
            } else {
                internalValue = convertToInternalUnit(weight)
            }
            startWeightOverride = internalValue
            startWeightDate = date
            persistence.saveStartWeightOverride(weight: internalValue, date: date)
            AppLogger.info("Updated start weight override — set=true", category: AppLogger.weightTracking)
        } else {
            startWeightOverride = nil
            startWeightDate = nil
            persistence.saveStartWeightOverride(weight: nil, date: nil)
            AppLogger.info("Updated start weight override — set=false", category: AppLogger.weightTracking)
        }
    }

    func setMilestoneCount(_ count: Int) {
        let sanitized = sanitizedMilestoneCount(count)
        milestoneCount = sanitized
        persistence.saveMilestoneCount(sanitized)
        AppLogger.info("Milestone count updated: \(sanitized)", category: AppLogger.weightTracking)
    }

    // MARK: - HealthKit Deletion Handling

    /// Handle weight deletions from HealthKit
    /// Following Apple HealthKit Programming Guide for deletion sync
    @objc private func handleHealthKitWeightDeletions(_ notification: Notification) {
        guard syncWithHealthKit,
              let userInfo = notification.userInfo,
              let deletedSamples = userInfo["deletedSamples"] as? [[String: Any]] else {
            return
        }

        AppLogger.info("Processing \(deletedSamples.count) deleted weight entries from HealthKit", category: AppLogger.weightTracking)

        var deletedCount = 0
        for deletedSample in deletedSamples {
            guard let dateValue = deletedSample["date"] as? Date,
                  let weightValue = deletedSample["weight"] as? Double else {
                continue
            }

            // Find and remove matching HealthKit entries using same deduplication logic
            // Following established patterns from syncFromHealthKit method
            weightEntries.removeAll { entry in
                entry.source == .healthKit &&
                    abs(entry.date.timeIntervalSince(dateValue)) < WeightConstants.DuplicationThreshold.tightTimeInterval && // Within 1 minute
                    abs(entry.weight - weightValue) < WeightConstants.DuplicationThreshold.weightDelta // Within 0.1 units
            }
            deletedCount += 1
        }

        if deletedCount > 0 {
            saveWeightEntries()
            AppLogger.info("Removed \(deletedCount) weight entries deleted from HealthKit", category: AppLogger.weightTracking)
        }
    }
}
