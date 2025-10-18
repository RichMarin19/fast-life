




















































































































































































































































































import Foundation
import Combine
import HealthKit

@MainActor
class WeightManager: ObservableObject {
    @Published var weightEntries: [WeightEntry] = []
    @Published var syncWithHealthKit: Bool = true

    // MARK: - Unit Preference Integration
    // Following Apple single source of truth pattern for global settings
    // Reference: https://developer.apple.com/documentation/swiftui/managing-user-interface-state
    private let appSettings = AppSettings.shared

    private let userDefaults = UserDefaults.standard
    private let weightEntriesKey = "weightEntries"
    private let syncHealthKitKey = "syncWithHealthKit"
    private var observerQuery: HKObserverQuery?

    // Industry standard: Suppress observer during manual operations to prevent duplicate sync
    // Following MyFitnessPal, Spotify pattern: Temporary flag during bidirectional operations
    // NOTE: nonisolated for thread-safe access from HealthKit background contexts
    private nonisolated(unsafe) var isSuppressingObserver: Bool = false


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
            HealthKitManager.shared.stopObserving(query: query)
        }

        // Remove deletion notification observer (Apple standard cleanup)
        NotificationCenter.default.removeObserver(self, name: .healthKitWeightDeleted, object: nil)
    }

    // MARK: - Add/Update Weight Entry

    func addWeightEntry(_ entry: WeightEntry) {
        // Industry Standard: All @Published property updates must be on main thread
        DispatchQueue.main.async {
            // Simply add the entry - allow multiple entries per day
            self.weightEntries.append(entry)

            // Sort by date (most recent first)
            self.weightEntries.sort { $0.date > $1.date }

            self.saveWeightEntries()
        }

        // Sync to HealthKit if enabled and this is a manual entry
        if syncWithHealthKit && entry.source == .manual {
            // INDUSTRY STANDARD: Temporarily suppress observer to prevent duplicate sync back
            // Following MyFitnessPal pattern: Manual → HealthKit should not trigger HealthKit → Manual
            isSuppressingObserver = true

            HealthKitManager.shared.saveWeight(weight: entry.weight, bmi: entry.bmi, bodyFat: entry.bodyFat, date: entry.date) { [weak self] success, error in
                // Re-enable observer after a brief delay to ensure HealthKit write completes
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    self?.isSuppressingObserver = false
                    AppLogger.info("Observer suppression lifted after manual entry sync", category: AppLogger.weightTracking)
                }

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
        // Industry Standard: All @Published property updates must be on main thread
        DispatchQueue.main.async {
            self.weightEntries.removeAll { $0.id == entry.id }
            self.saveWeightEntries()
        }

        // BIDIRECTIONAL DELETION: Delete from HealthKit for ANY entry when sync is enabled
        // Following Apple HealthKit best practices: Use UUID-based deletion for precision
        // Reference: Apple HealthKit Programming Guide - precise sample deletion
        if syncWithHealthKit {
            AppLogger.info("Bidirectional deletion: removing weight entry from HealthKit (source: \(entry.source))", category: AppLogger.weightTracking)

            if let healthKitUUID = entry.healthKitUUID {
                // PRECISE DELETION: Use UUID for exact sample targeting (Apple best practice)
                HealthKitManager.shared.deleteWeightByUUID(healthKitUUID) { success, error in
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
                HealthKitManager.shared.findWeightSampleUUID(date: entry.date, weight: entry.weight) { uuid in
                    if let foundUUID = uuid {
                        AppLogger.info("Found HealthKit UUID via query - proceeding with precise deletion", category: AppLogger.weightTracking)
                        HealthKitManager.shared.deleteWeightByUUID(foundUUID) { success, error in
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

    // MARK: - Unit Conversion Methods
    // Following Apple adapter pattern to maintain backward compatibility
    // Reference: https://docs.swift.org/swift-book/LanguageGuide/Protocols.html#ID521

    /// Convert weight entry to user's preferred unit for display
    /// Maintains backward compatibility while supporting unit preferences
    func displayWeight(for entry: WeightEntry) -> Double {
        return appSettings.weightUnit.fromPounds(entry.weight)
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

    /// Add weight entry from user input in preferred unit
    /// Following Apple data conversion pattern for user input
    /// Reference: https://developer.apple.com/documentation/foundation/measurement
    func addWeightEntryInPreferredUnit(weight: Double, bmi: Double? = nil, bodyFat: Double? = nil, date: Date = Date()) {
        let weightInPounds = appSettings.weightUnit.toPounds(weight)

        // Following roadmap requirement: "ensure edits do not create duplicates"
        // FIXED: Check across ALL sources, not just manual (Industry standard pattern)
        let isDuplicate = weightEntries.contains(where: {
            // Check ANY existing entry (Manual OR HealthKit) to prevent bidirectional duplicates
            abs($0.date.timeIntervalSince(date)) < 1800 && // Within 30 minutes
            abs($0.weight - weightInPounds) < 0.1 // Within 0.1 lbs
        })

        guard !isDuplicate else {
            AppLogger.warning("Prevented duplicate weight entry within 30 minutes", category: AppLogger.weightTracking)
            return
        }

        AppLogger.info("Adding weight entry", category: AppLogger.weightTracking)

        let entry = WeightEntry(
            date: date,
            weight: weightInPounds,
            bmi: bmi,
            bodyFat: bodyFat,
            source: .manual
        )
        addWeightEntry(entry)
    }

    /// Check if a potential weight entry would be a duplicate
    /// Following Apple validation pattern for user input
    /// Reference: https://developer.apple.com/documentation/foundation/formatter/creating_a_custom_formatter
    func wouldCreateDuplicate(weight: Double, date: Date = Date()) -> Bool {
        let weightInPounds = appSettings.weightUnit.toPounds(weight)
        return weightEntries.contains(where: {
            // FIXED: Check across ALL sources, not just manual (Industry standard pattern)
            // This prevents Manual vs HealthKit duplicates that were causing the issue
            abs($0.date.timeIntervalSince(date)) < 1800 && // Within 30 minutes
            abs($0.weight - weightInPounds) < 0.1 // Within 0.1 lbs
        })
    }

    // MARK: - Sync with HealthKit

    func syncFromHealthKit(startDate: Date? = nil, completion: ((Int, Error?) -> Void)? = nil) {
        guard syncWithHealthKit else {
            completion?(0, NSError(domain: "WeightManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "HealthKit sync is disabled"]))
            return
        }

        // Default to comprehensive sync (10 years) for data consistency with manual sync
        // Industry Standard: Use same wide date range as manual sync to ensure identical results
        let start = startDate ?? Calendar.current.date(byAdding: .year, value: -10, to: Date())!

        HealthKitManager.shared.fetchWeightData(startDate: start, resetAnchor: false) { [weak self] healthKitEntries in
            guard let self = self else {
                completion?(0, NSError(domain: "WeightManager", code: 2, userInfo: [NSLocalizedDescriptionKey: "WeightManager instance deallocated"]))
                return
            }

            // Industry Standard: All @Published property updates must be on main thread (SwiftUI + HealthKit best practice)
            DispatchQueue.main.async {
                // Track newly added entries for accurate reporting
                var newlyAddedCount = 0

            // Merge HealthKit entries with local entries
            for hkEntry in healthKitEntries {
                // Check if we already have this exact entry (by date AND time, not just day)
                // FIXED: Check across ALL sources to prevent Manual vs HealthKit duplicates
                // Following Apple HealthKit best practices for duplicate detection
                // Reference: https://developer.apple.com/documentation/healthkit/about_the_healthkit_framework
                let isDuplicate = self.weightEntries.contains(where: {
                    // Check ANY existing entry (Manual OR HealthKit) to prevent bidirectional duplicates
                    abs($0.date.timeIntervalSince(hkEntry.date)) < 60 && // Within 1 minute
                    abs($0.weight - hkEntry.weight) < 0.1 // Within 0.1 lbs (≈0.045 kg)
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

            // Industry Standard: All @Published property updates must be on main thread (SwiftUI + HealthKit best practice)
            DispatchQueue.main.async {
                // Track newly added entries for accurate reporting
                var newlyAddedCount = 0

                // Merge HealthKit entries with local entries using robust deduplication
                for hkEntry in healthKitEntries {
                    // More comprehensive duplicate check for historical data
                    // FIXED: Check across ALL sources to prevent Manual vs HealthKit duplicates
                    let isDuplicate = self.weightEntries.contains(where: {
                        // Check if entry already exists across ANY source (Manual OR HealthKit)
                        // Following Apple HealthKit historical sync best practices
                        abs($0.date.timeIntervalSince(hkEntry.date)) < 300 && // Within 5 minutes (more flexible for historical)
                        abs($0.weight - hkEntry.weight) < 0.2 // Within 0.2 lbs (≈0.09 kg) account for rounding
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

                completion(newlyAddedCount, nil)
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

        AppLogger.info("Starting manual sync with anchor reset for deletion detection from \(startDate)", category: AppLogger.weightTracking)

        HealthKitManager.shared.fetchWeightData(startDate: startDate, resetAnchor: true) { [weak self] healthKitEntries in
            guard let self = self else {
                completion(0, NSError(domain: "WeightManager", code: 2, userInfo: [NSLocalizedDescriptionKey: "WeightManager instance deallocated"]))
                return
            }

            // Industry Standard: All @Published property updates must be on main thread (SwiftUI + HealthKit best practice)
            DispatchQueue.main.async {
                // Industry Standard: Complete sync with deletion detection
                // Step 1: Remove HealthKit entries that are no longer in Apple Health
                let originalCount = self.weightEntries.count
                let formatter = DateFormatter()
                formatter.dateFormat = "MMM d 'at' h:mm a"

                AppLogger.info("DELETION CHECK: Starting with \(originalCount) Fast LIFe entries, \(healthKitEntries.count) HealthKit entries", category: AppLogger.weightTracking)

                self.weightEntries.removeAll { fastLifeEntry in
                    // Only remove HealthKit-sourced entries (preserve manual entries)
                    guard fastLifeEntry.source != .manual else {
                        AppLogger.info("PRESERVING manual entry: \(fastLifeEntry.weight)lbs on \(formatter.string(from: fastLifeEntry.date))", category: AppLogger.weightTracking)
                        return false
                    }

                    // Check if this Fast LIFe entry still exists in current HealthKit data
                    let stillExistsInHealthKit = healthKitEntries.contains { healthKitEntry in
                        let timeDiff = abs(fastLifeEntry.date.timeIntervalSince(healthKitEntry.date))
                        let weightDiff = abs(fastLifeEntry.weight - healthKitEntry.weight)
                        return timeDiff < 60 && weightDiff < 0.1
                    }

                    let fastLifeDateString = formatter.string(from: fastLifeEntry.date)

                    if !stillExistsInHealthKit {
                        AppLogger.info("DELETING entry: \(fastLifeEntry.weight)lbs on \(fastLifeDateString) (source: \(fastLifeEntry.source.rawValue)) - not found in current HealthKit data", category: AppLogger.weightTracking)
                    } else {
                        AppLogger.info("KEEPING entry: \(fastLifeEntry.weight)lbs on \(fastLifeDateString) (source: \(fastLifeEntry.source.rawValue)) - still exists in HealthKit", category: AppLogger.weightTracking)
                    }

                    return !stillExistsInHealthKit
                }
                let deletedCount = originalCount - self.weightEntries.count
                AppLogger.info("DELETION COMPLETE: Removed \(deletedCount) entries, \(self.weightEntries.count) entries remaining", category: AppLogger.weightTracking)

                // Step 2: Add new HealthKit entries not already in Fast LIFe
                var addedCount = 0
                AppLogger.info("Starting comparison: HealthKit has \(healthKitEntries.count) entries, Fast LIFe has \(self.weightEntries.count) entries", category: AppLogger.weightTracking)

                for healthKitEntry in healthKitEntries {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "MMM d 'at' h:mm a"
                    let healthKitDateString = formatter.string(from: healthKitEntry.date)

                    let alreadyExists = self.weightEntries.contains { fastLifeEntry in
                        let timeDiff = abs(fastLifeEntry.date.timeIntervalSince(healthKitEntry.date))
                        let weightDiff = abs(fastLifeEntry.weight - healthKitEntry.weight)
                        let fastLifeDateString = formatter.string(from: fastLifeEntry.date)

                        let matches = timeDiff < 60 && weightDiff < 0.1

                        if matches {
                            AppLogger.info("MATCH FOUND: HealthKit(\(healthKitEntry.weight)lbs \(healthKitDateString)) matches Fast LIFe(\(fastLifeEntry.weight)lbs \(fastLifeDateString)) - timeDiff:\(timeDiff)s weightDiff:\(weightDiff)lbs", category: AppLogger.weightTracking)
                        }

                        return matches
                    }

                    if !alreadyExists {
                        AppLogger.info("MISSING ENTRY DETECTED: Adding HealthKit entry \(healthKitEntry.weight)lbs on \(healthKitDateString) (source: \(healthKitEntry.source.rawValue))", category: AppLogger.weightTracking)
                        self.weightEntries.append(healthKitEntry)
                        addedCount += 1
                    } else {
                        AppLogger.info("Entry already exists: \(healthKitEntry.weight)lbs on \(healthKitDateString)", category: AppLogger.weightTracking)
                    }
                }

                // Sort by date (most recent first) and save
                self.weightEntries.sort { $0.date > $1.date }
                self.saveWeightEntries()

                // Report comprehensive sync results
                AppLogger.info("Manual HealthKit sync completed: \(addedCount) entries added, \(deletedCount) entries removed, \(healthKitEntries.count) total HealthKit entries", category: AppLogger.weightTracking)

                completion(addedCount, nil)
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
            let isAuthorized = HealthKitManager.shared.isWeightAuthorized()
            AppLogger.info("Weight-specific HealthKit authorization status: \(isAuthorized ? "granted" : "denied")", category: AppLogger.weightTracking)

            if !isAuthorized {
                AppLogger.info("Requesting weight-specific HealthKit authorization", category: AppLogger.weightTracking)
                HealthKitManager.shared.requestWeightAuthorization { success, error in
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
                HealthKitManager.shared.stopObserving(query: query)
                observerQuery = nil
            }
        }
    }

    // MARK: - HealthKit Observer

    private func setupHealthKitObserver() {
        // Only setup observer if sync is enabled and specifically authorized for weight data
        // Following Apple HealthKit best practices: observers need specific data type authorization
        guard syncWithHealthKit && HealthKitManager.shared.isWeightAuthorized() else {
            AppLogger.info("Weight observer not set up - sync disabled or not authorized for weight data", category: AppLogger.weightTracking)
            return
        }

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

            // INDUSTRY STANDARD: Check if observer is suppressed (manual operation in progress)
            guard let self = self, !self.isSuppressingObserver else {
                AppLogger.info("HealthKit observer suppressed during manual operation - skipping sync", category: AppLogger.weightTracking)
                completionHandler()
                return
            }

            // New weight data detected - sync with comprehensive date range
            // Industry Standard: Use anchored query (handles deletions) with wide date range for consistency
            AppLogger.info("New weight data detected in HealthKit, syncing with deletion support", category: AppLogger.weightTracking)
            DispatchQueue.main.async {
                let startDate = Calendar.current.date(byAdding: .year, value: -10, to: Date()) ?? Date()
                self.syncFromHealthKit(startDate: startDate, completion: nil)
            }

            // Must call completion handler
            completionHandler()
        }

        observerQuery = query
        HealthKitManager.shared.startObserving(query: query)
        AppLogger.info("Weight HealthKit observer started successfully - automatic sync enabled", category: AppLogger.weightTracking)
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
                abs(entry.date.timeIntervalSince(dateValue)) < 60 && // Within 1 minute
                abs(entry.weight - weightValue) < 0.1 // Within 0.1 lbs
            }
            deletedCount += 1
        }

        if deletedCount > 0 {
            saveWeightEntries()
            AppLogger.info("Removed \(deletedCount) weight entries deleted from HealthKit", category: AppLogger.weightTracking)
        }
    }
}
