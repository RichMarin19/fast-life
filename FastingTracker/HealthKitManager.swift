import Foundation
import HealthKit

// MARK: - Notification Names for HealthKit Deletions
extension Notification.Name {
    static let healthKitWeightDeleted = Notification.Name("healthKitWeightDeleted")
    static let healthKitSleepDeleted = Notification.Name("healthKitSleepDeleted")
    static let healthKitHydrationDeleted = Notification.Name("healthKitHydrationDeleted")
}

class HealthKitManager: ObservableObject {
    static let shared = HealthKitManager()

    private let healthStore = HKHealthStore()
    @Published var isAuthorized = false

    // MARK: - Anchored Query Storage
    // Following Apple HealthKit Best Practices for HKAnchoredObjectQuery
    // Reference: https://developer.apple.com/documentation/healthkit/hkanchoredobjectquery

    private let userDefaults = UserDefaults.standard
    private enum AnchorKeys {
        static let weight = "HealthKitAnchor_Weight"
        static let water = "HealthKitAnchor_Water"
        static let sleep = "HealthKitAnchor_Sleep"
        static let fasting = "HealthKitAnchor_Fasting"
    }

    // MARK: - Sync Timestamp Tracking
    // Following Apple Settings app pattern for sync status display
    // Reference: https://developer.apple.com/design/human-interface-guidelines/components/status/indicators/

    private enum SyncTimestampKeys {
        static let weight = "HealthKitSyncTimestamp_Weight"
        static let water = "HealthKitSyncTimestamp_Water"
        static let sleep = "HealthKitSyncTimestamp_Sleep"
        static let fasting = "HealthKitSyncTimestamp_Fasting"
        static let allData = "HealthKitSyncTimestamp_AllData"
    }

    // MARK: - Sync Error State Tracking
    // Following Apple error handling guidelines for graceful failure states
    // Reference: https://developer.apple.com/design/human-interface-guidelines/patterns/feedback/

    private enum SyncErrorKeys {
        static let weight = "HealthKitSyncError_Weight"
        static let water = "HealthKitSyncError_Water"
        static let sleep = "HealthKitSyncError_Sleep"
        static let fasting = "HealthKitSyncError_Fasting"
        static let allData = "HealthKitSyncError_AllData"
    }

    private init() {
        checkAuthorizationStatus()
    }

    // MARK: - Authorization

    // MARK: - Domain-Specific Authorization Checks

    func isWeightAuthorized() -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else {
            return false
        }

        guard let weightType = HKObjectType.quantityType(forIdentifier: .bodyMass) else {
            return false
        }

        let status = healthStore.authorizationStatus(for: weightType)
        return status == .sharingAuthorized
    }

    /// Returns the detailed HealthKit authorization status for weight data
    /// Following Apple HealthKit Programming Guide for proper authorization state handling
    func getWeightAuthorizationStatus() -> HKAuthorizationStatus {
        guard HKHealthStore.isHealthDataAvailable(),
              let weightType = HKObjectType.quantityType(forIdentifier: .bodyMass) else {
            return .notDetermined
        }

        return healthStore.authorizationStatus(for: weightType)
    }

    func isWaterAuthorized() -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else {
            return false
        }

        guard let waterType = HKObjectType.quantityType(forIdentifier: .dietaryWater) else {
            return false
        }

        let status = healthStore.authorizationStatus(for: waterType)
        return status == .sharingAuthorized
    }

    func isSleepAuthorized() -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else {
            return false
        }

        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            return false
        }

        let status = healthStore.authorizationStatus(for: sleepType)
        return status == .sharingAuthorized
    }

    func isFastingAuthorized() -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else {
            return false
        }

        // Fasting sessions are stored as workouts in HealthKit
        let workoutType = HKObjectType.workoutType()
        let status = healthStore.authorizationStatus(for: workoutType)
        return status == .sharingAuthorized
    }

    /// Returns the detailed HealthKit authorization status for fasting data (workouts)
    /// Following Apple HealthKit Programming Guide for proper authorization state handling
    func getFastingAuthorizationStatus() -> HKAuthorizationStatus {
        guard HKHealthStore.isHealthDataAvailable() else {
            return .notDetermined
        }

        let workoutType = HKObjectType.workoutType()
        return healthStore.authorizationStatus(for: workoutType)
    }

    func checkAuthorizationStatus() {
        guard HKHealthStore.isHealthDataAvailable() else {
            AppLogger.warning("HealthKit is not available on this device", category: AppLogger.healthKit)
            return
        }

        // Check authorization for both weight and water
        let weightType = HKObjectType.quantityType(forIdentifier: .bodyMass)!
        let waterType = HKObjectType.quantityType(forIdentifier: .dietaryWater)!

        let weightStatus = healthStore.authorizationStatus(for: weightType)
        let waterStatus = healthStore.authorizationStatus(for: waterType)

        // Authorized if either weight or water is authorized
        isAuthorized = (weightStatus == .sharingAuthorized || waterStatus == .sharingAuthorized)
    }

    // MARK: - Granular Authorization Requests
    // Per Apple best practices: Request permissions only when needed, per domain
    // Reference: https://developer.apple.com/documentation/healthkit/protecting_user_privacy

    /// Request authorization for weight tracking only (bodyMass, BMI, body fat)
    /// Refactored to use shared HealthKitService - eliminates code duplication
    func requestWeightAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        HealthKitService.requestWeightAuthorization(completion: completion)
    }

    /// Request authorization for hydration tracking only (dietary water)
    /// Refactored to use shared HealthKitService - eliminates code duplication
    func requestHydrationAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        HealthKitService.requestHydrationAuthorization(completion: completion)
    }

    /// Request authorization for sleep tracking only (sleep analysis)
    /// Refactored to use shared HealthKitService - eliminates code duplication
    func requestSleepAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        HealthKitService.requestSleepAuthorization(completion: completion)
    }

    /// Request authorization for fasting tracking (stored as workouts in HealthKit)
    /// Refactored to use shared HealthKitService - eliminates code duplication
    func requestFastingAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        HealthKitService.requestFastingAuthorization(completion: completion)
    }

    // MARK: - Legacy Authorization (For "Sync All" Features Only)
    // NOTE: This method requests ALL permissions at once
    // USAGE: Only use for "Sync All" features where requesting all permissions simultaneously is intentional
    // For individual features, use domain-specific methods: requestWeightAuthorization(), requestHydrationAuthorization(), requestSleepAuthorization()
    // Reference: https://developer.apple.com/documentation/healthkit/protecting_user_privacy
    /// Comprehensive authorization for all data types (legacy method for "Sync All" features)
    /// Refactored to use shared HealthKitService - eliminates code duplication
    func requestAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        HealthKitService.requestComprehensiveAuthorization { [weak self] success, error in
            DispatchQueue.main.async {
                self?.isAuthorized = success
                completion(success, error)
            }
        }
    }

    // MARK: - Anchor Management for HKAnchoredObjectQuery
    // Following Apple HealthKit Best Practices to prevent duplicates and improve sync performance
    // Reference: https://developer.apple.com/documentation/healthkit/hkanchoredobjectquery

    private func saveAnchor(_ anchor: HKQueryAnchor?, forKey key: String) {
        guard let anchor = anchor else { return }

        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: anchor, requiringSecureCoding: true)
            userDefaults.set(data, forKey: key)
            AppLogger.info("Saved HealthKit anchor", category: AppLogger.healthKit)
        } catch {
            AppLogger.error("Failed to save HealthKit anchor", category: AppLogger.healthKit, error: error)
        }
    }

    private func loadAnchor(forKey key: String) -> HKQueryAnchor? {
        guard let data = userDefaults.data(forKey: key) else {
            AppLogger.info("No saved HealthKit anchor found - first sync", category: AppLogger.healthKit)
            return nil
        }

        do {
            let anchor = try NSKeyedUnarchiver.unarchivedObject(ofClass: HKQueryAnchor.self, from: data)
            AppLogger.info("Loaded saved HealthKit anchor", category: AppLogger.healthKit)
            return anchor
        } catch {
            AppLogger.error("Failed to load HealthKit anchor", category: AppLogger.healthKit, error: error)
            // Clear corrupted anchor data
            userDefaults.removeObject(forKey: key)
            return nil
        }
    }

    /// Saves sync timestamp for a specific data type
    /// Following iOS Settings app pattern for displaying "Last synced" information
    private func saveSyncTimestamp(for dataType: String, timestamp: Date = Date()) {
        userDefaults.set(timestamp, forKey: dataType)
        AppLogger.info("Saved sync timestamp for \(dataType)", category: AppLogger.healthKit)
    }

    /// Loads sync timestamp for a specific data type
    private func loadSyncTimestamp(for dataType: String) -> Date? {
        return userDefaults.object(forKey: dataType) as? Date
    }

    /// Saves sync error state for a specific data type
    /// Following Apple error handling patterns for user-friendly error states
    private func saveSyncError(for dataType: String, error: String?) {
        if let error = error {
            userDefaults.set(error, forKey: dataType)
            AppLogger.error("Saved sync error for \(dataType): \(error)", category: AppLogger.healthKit)
        } else {
            // Clear error on successful sync
            userDefaults.removeObject(forKey: dataType)
        }
    }

    /// Loads sync error for a specific data type
    private func loadSyncError(for dataType: String) -> String? {
        return userDefaults.string(forKey: dataType)
    }

    // MARK: - Public Sync Status API
    // Following Apple Human Interface Guidelines for status indicators
    // Reference: https://developer.apple.com/design/human-interface-guidelines/components/status/indicators/

    /// Returns the last sync timestamp for weight data
    public var lastWeightSyncDate: Date? {
        return loadSyncTimestamp(for: SyncTimestampKeys.weight)
    }

    /// Returns the last sync timestamp for water data
    public var lastWaterSyncDate: Date? {
        return loadSyncTimestamp(for: SyncTimestampKeys.water)
    }

    /// Returns the last sync timestamp for sleep data
    public var lastSleepSyncDate: Date? {
        return loadSyncTimestamp(for: SyncTimestampKeys.sleep)
    }

    /// Returns the last sync timestamp for fasting data
    public var lastFastingSyncDate: Date? {
        return loadSyncTimestamp(for: SyncTimestampKeys.fasting)
    }

    /// Returns the timestamp for when "Sync All Health Data" was last executed
    /// This is separate from individual data type syncs to avoid confusion
    public var lastAllDataSyncDate: Date? {
        return loadSyncTimestamp(for: SyncTimestampKeys.allData)
    }

    // MARK: - Public Error State API
    // Following Apple Human Interface Guidelines for error feedback
    // Reference: https://developer.apple.com/design/human-interface-guidelines/patterns/feedback/

    /// Returns the last sync error for weight data, if any
    public var lastWeightSyncError: String? {
        return loadSyncError(for: SyncErrorKeys.weight)
    }

    /// Returns the last sync error for water data, if any
    public var lastWaterSyncError: String? {
        return loadSyncError(for: SyncErrorKeys.water)
    }

    /// Returns the last sync error for sleep data, if any
    public var lastSleepSyncError: String? {
        return loadSyncError(for: SyncErrorKeys.sleep)
    }

    /// Returns the last sync error for fasting data, if any
    public var lastFastingSyncError: String? {
        return loadSyncError(for: SyncErrorKeys.fasting)
    }

    /// Returns true if any data type has a sync error
    public var hasSyncErrors: Bool {
        return [lastWeightSyncError, lastWaterSyncError, lastSleepSyncError, lastFastingSyncError]
            .compactMap { $0 }
            .count > 0
    }

    // MARK: - Public Sync Status Update Methods
    // Following Apple HealthKit Best Practices for manual sync timestamp updates
    // Reference: https://developer.apple.com/documentation/healthkit/hkanchoredobjectquery

    /// Manually update sync timestamp for weight data (called after successful sync operations)
    public func updateWeightSyncStatus(success: Bool, error: String? = nil) {
        if success {
            saveSyncTimestamp(for: SyncTimestampKeys.weight)
            saveSyncError(for: SyncErrorKeys.weight, error: nil)
        } else {
            saveSyncError(for: SyncErrorKeys.weight, error: error ?? "Sync failed")
        }
    }

    /// Manually update sync timestamp for water data (called after successful sync operations)
    public func updateWaterSyncStatus(success: Bool, error: String? = nil) {
        if success {
            saveSyncTimestamp(for: SyncTimestampKeys.water)
            saveSyncError(for: SyncErrorKeys.water, error: nil)
        } else {
            saveSyncError(for: SyncErrorKeys.water, error: error ?? "Sync failed")
        }
    }

    /// Manually update sync timestamp for sleep data (called after successful sync operations)
    public func updateSleepSyncStatus(success: Bool, error: String? = nil) {
        if success {
            saveSyncTimestamp(for: SyncTimestampKeys.sleep)
            saveSyncError(for: SyncErrorKeys.sleep, error: nil)
        } else {
            saveSyncError(for: SyncErrorKeys.sleep, error: error ?? "Sync failed")
        }
    }

    /// Manually update sync timestamp for fasting data (called after successful sync operations)
    public func updateFastingSyncStatus(success: Bool, error: String? = nil) {
        if success {
            saveSyncTimestamp(for: SyncTimestampKeys.fasting)
            saveSyncError(for: SyncErrorKeys.fasting, error: nil)
        } else {
            saveSyncError(for: SyncErrorKeys.fasting, error: error ?? "Sync failed")
        }
    }

    /// Manually update sync timestamp for "Sync All Health Data" operation
    /// Only call this when the comprehensive sync operation is performed
    public func updateAllDataSyncStatus(success: Bool, error: String? = nil) {
        if success {
            saveSyncTimestamp(for: SyncTimestampKeys.allData)
            saveSyncError(for: SyncErrorKeys.allData, error: nil)
        } else {
            saveSyncError(for: SyncErrorKeys.allData, error: error ?? "Comprehensive sync failed")
        }
    }

    // MARK: - Source Detection Helper

    /// Detect the actual data source from HealthKit sample
    /// Following Apple HealthKit Programming Guide for source attribution
    /// Reference: https://developer.apple.com/documentation/healthkit/hksource
    private func detectWeightSource(from sample: HKQuantitySample) -> WeightSource {
        let bundleIdentifier = sample.sourceRevision.source.bundleIdentifier
        let sourceName = sample.sourceRevision.source.name

        AppLogger.info("Detecting source for sample: bundleId=\(bundleIdentifier), name=\(sourceName)", category: AppLogger.healthKit)

        // Industry standard source detection patterns
        // Reference: MyFitnessPal, Lose It source attribution
        switch bundleIdentifier {
        case let id where id.contains("renpho"):
            return .renpho
        case "com.apple.Health":
            // Direct entry in Apple Health app
            return .healthKit
        case let id where id.contains("scale") || id.contains("weight"):
            // Generic smart scale apps
            return .other
        default:
            // Unknown source - check name as fallback
            if sourceName.lowercased().contains("renpho") {
                return .renpho
            } else if sourceName.lowercased().contains("scale") {
                return .other
            } else {
                return .healthKit
            }
        }
    }

    // MARK: - Read Weight Data

    /// Fetches weight data using HKAnchoredObjectQuery for efficient incremental sync
    /// Following Apple HealthKit Best Practices to prevent duplicates and improve performance
    /// Reference: https://developer.apple.com/documentation/healthkit/hkanchoredobjectquery
    func fetchWeightData(startDate: Date, endDate: Date = Date(), resetAnchor: Bool = false, completion: @escaping ([WeightEntry]) -> Void) {
        fetchWeightDataAnchored(startDate: startDate, endDate: endDate, resetAnchor: resetAnchor, completion: completion)
    }

    private func fetchWeightDataAnchored(startDate: Date, endDate: Date = Date(), resetAnchor: Bool = false, completion: @escaping ([WeightEntry]) -> Void) {
        guard let weightType = HKObjectType.quantityType(forIdentifier: .bodyMass) else {
            completion([])
            return
        }

        // Load previously saved anchor for incremental sync, or reset if requested
        // Industry Standard: Reset anchor for manual sync to detect missed deletions
        let savedAnchor = resetAnchor ? nil : loadAnchor(forKey: AnchorKeys.weight)

        if resetAnchor {
            AppLogger.info("Resetting HealthKit anchor for fresh deletion detection", category: AppLogger.healthKit)
        }

        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)

        // Use HKAnchoredObjectQuery instead of HKSampleQuery for better performance and duplicate prevention
        let query = HKAnchoredObjectQuery(
            type: weightType,
            predicate: predicate,
            anchor: savedAnchor,
            limit: HKObjectQueryNoLimit
        ) { [weak self] query, addedObjects, deletedObjects, newAnchor, error in

            // Apply industry-standard HKError handling
            if let error = error {
                let errorMessage = self?.handleHealthKitError(error, operation: "fetch weight data (anchored)") ?? "Unknown error"
                AppLogger.error("Enhanced error handling for anchored weight fetch: \(errorMessage)", category: AppLogger.healthKit, error: error)

                // Save error state for UI display with user-friendly message
                self?.saveSyncError(for: SyncErrorKeys.weight, error: errorMessage)

                // Record for production crash analysis with enhanced context
                CrashReportManager.shared.recordHealthKitError(error, context: [
                    "operation": "fetchWeightData_anchored",
                    "startDate": startDate.description,
                    "anchor": savedAnchor?.description ?? "nil",
                    "userFriendlyError": errorMessage
                ])

                completion([])
                return
            }

            // Save the new anchor for next sync
            self?.saveAnchor(newAnchor, forKey: AnchorKeys.weight)

            // Save sync timestamp and clear any previous errors
            self?.saveSyncTimestamp(for: SyncTimestampKeys.weight)
            self?.saveSyncError(for: SyncErrorKeys.weight, error: nil)

            // Process deleted samples first (Apple best practice)
            if let deletedSamples = deletedObjects as? [HKQuantitySample], !deletedSamples.isEmpty {
                AppLogger.info("Processing \(deletedSamples.count) deleted weight samples from HealthKit", category: AppLogger.healthKit)
                self?.processDeletedWeightSamples(deletedSamples)
            }

            // Process added samples
            guard let samples = addedObjects as? [HKQuantitySample] else {
                completion([])
                return
            }

            AppLogger.info("Fetched \(samples.count) weight samples from HealthKit", category: AppLogger.healthKit)

            // DEBUG: Log first few samples to see what we're getting
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d 'at' h:mm a"
            for (index, sample) in samples.prefix(10).enumerated() {
                let weight = sample.quantity.doubleValue(for: HKUnit.pound())
                let dateString = formatter.string(from: sample.startDate)
                let source = self?.detectWeightSource(from: sample) ?? .other
                AppLogger.info("HealthKit sample \(index): \(weight)lbs on \(dateString) (source: \(source.rawValue))", category: AppLogger.healthKit)
            }

            // Process samples same as before (group by date, get most recent per day)
            self?.processWeightSamples(samples, completion: completion)
        }

        healthStore.execute(query)
    }

    /// Legacy method for backward compatibility - uses HKSampleQuery
    /// Consider migrating all calls to use anchored version for better performance
    func fetchWeightDataLegacy(startDate: Date, endDate: Date = Date(), completion: @escaping ([WeightEntry]) -> Void) {
        guard let weightType = HKObjectType.quantityType(forIdentifier: .bodyMass) else {
            completion([])
            return
        }

        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        let query = HKSampleQuery(sampleType: weightType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { [weak self] query, results, error in

            // Apply industry-standard HKError handling
            if let error = error {
                let errorMessage = self?.handleHealthKitError(error, operation: "fetch weight data") ?? "Unknown error"
                AppLogger.error("Enhanced error handling for weight fetch: \(errorMessage)", category: AppLogger.healthKit, error: error)

                // Update sync status with specific error
                self?.updateWeightSyncStatus(success: false, error: errorMessage)
                completion([])
                return
            }

            guard let samples = results as? [HKQuantitySample] else {
                AppLogger.warning("No weight samples returned from HealthKit", category: AppLogger.healthKit)
                completion([])
                return
            }

            // Group by date (one entry per day, taking the most recent)
            var entriesByDay: [Date: HKQuantitySample] = [:]
            let calendar = Calendar.current

            for sample in samples {
                let day = calendar.startOfDay(for: sample.startDate)

                // Keep the most recent sample for each day
                if let existing = entriesByDay[day] {
                    if sample.startDate > existing.startDate {
                        entriesByDay[day] = sample
                    }
                } else {
                    entriesByDay[day] = sample
                }
            }

            // Convert to WeightEntry objects
            var weightEntries: [WeightEntry] = []

            for (date, sample) in entriesByDay {
                let weightInPounds = sample.quantity.doubleValue(for: HKUnit.pound())

                // Fetch BMI and body fat for this date if available
                self?.fetchBMIAndBodyFat(for: date) { bmi, bodyFat in
                    // INDUSTRY STANDARD: Detect actual data source (Renpho, Apple Health, etc.)
                    let actualSource = self?.detectWeightSource(from: sample) ?? .healthKit
                    let entry = WeightEntry(
                        date: sample.startDate,
                        weight: weightInPounds,
                        bmi: bmi,
                        bodyFat: bodyFat,
                        source: actualSource,
                        healthKitUUID: sample.uuid  // Store UUID for precise deletion (Apple best practice)
                    )
                    weightEntries.append(entry)

                    // Call completion when all entries are processed
                    if weightEntries.count == entriesByDay.count {
                        DispatchQueue.main.async {
                            completion(weightEntries.sorted { $0.date > $1.date })
                        }
                    }
                }
            }

            // Handle case where there are no samples
            if entriesByDay.isEmpty {
                DispatchQueue.main.async {
                    completion([])
                }
            }
        }

        healthStore.execute(query)
    }

    /// Processes weight samples by grouping by date and fetching associated BMI/body fat data
    private func processWeightSamples(_ samples: [HKQuantitySample], completion: @escaping ([WeightEntry]) -> Void) {
        // INDUSTRY STANDARD FIX: Preserve ALL weight entries (multiple per day allowed)
        // Following MyFitnessPal, Lose It pattern: Users want complete weight tracking history
        // Remove the "one entry per day" filtering that was causing data loss

        AppLogger.info("Processing \(samples.count) weight samples from HealthKit (preserving all entries)", category: AppLogger.healthKit)

        // Convert all samples to WeightEntry objects (no filtering)
        var weightEntries: [WeightEntry] = []

        for sample in samples {
            let weightInPounds = sample.quantity.doubleValue(for: HKUnit.pound())

            // INDUSTRY STANDARD: Detect actual data source (Renpho, Apple Health, etc.)
            let actualSource = self.detectWeightSource(from: sample)
            let entry = WeightEntry(
                date: sample.startDate,
                weight: weightInPounds,
                source: actualSource,
                healthKitUUID: sample.uuid
            )
            weightEntries.append(entry)
        }

        // Sort by date (most recent first) and return all entries
        weightEntries.sort { $0.date > $1.date }
        AppLogger.info("Processed \(weightEntries.count) weight entries from HealthKit", category: AppLogger.healthKit)
        completion(weightEntries)
    }
    /// Process deleted weight samples from HealthKit
    /// Following Apple HealthKit Programming Guide for deletion handling
    private func processDeletedWeightSamples(_ deletedSamples: [HKQuantitySample]) {
        // Notify all active WeightManager instances about deletions
        // Using NotificationCenter for loose coupling (Apple pattern)
        let deletedObjects = deletedSamples.map { sample in
            [
                "uuid": sample.uuid.uuidString,
                "date": sample.startDate,
                "weight": sample.quantity.doubleValue(for: HKUnit.pound())
            ]
        }

        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: .healthKitWeightDeleted,
                object: nil,
                userInfo: ["deletedSamples": deletedObjects]
            )
        }

        AppLogger.info("Notified WeightManager instances of \(deletedSamples.count) deleted weight entries", category: AppLogger.healthKit)
    }

    /// Fetch ALL historical weight data from HealthKit (no anchor - full import)
    /// Following Apple HealthKit Programming Guide: Complete data import for user choice
    /// Used when user selects "Import All Historical Data" sync preference
    func fetchWeightDataHistorical(startDate: Date, endDate: Date = Date(), completion: @escaping ([WeightEntry]) -> Void) {
        guard let weightType = HKObjectType.quantityType(forIdentifier: .bodyMass) else {
            completion([])
            return
        }

        AppLogger.info("Starting historical weight data fetch from \(startDate) to \(endDate)", category: AppLogger.healthKit)

        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        // Use HKSampleQuery (not anchored) for complete historical import
        let query = HKSampleQuery(sampleType: weightType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { [weak self] query, results, error in

            // Apply industry-standard HKError handling
            if let error = error {
                let errorMessage = self?.handleHealthKitError(error, operation: "fetch historical weight data") ?? "Unknown error"
                AppLogger.error("Historical weight fetch error: \(errorMessage)", category: AppLogger.healthKit, error: error)

                // Record for crash analysis with historical import context
                CrashReportManager.shared.recordHealthKitError(error, context: [
                    "operation": "fetchWeightDataHistorical",
                    "startDate": startDate.description,
                    "endDate": endDate.description,
                    "userFriendlyError": errorMessage
                ])

                completion([])
                return
            }

            guard let samples = results as? [HKQuantitySample] else {
                AppLogger.warning("No historical weight samples returned from HealthKit", category: AppLogger.healthKit)
                completion([])
                return
            }

            AppLogger.info("Fetched \(samples.count) historical weight samples from HealthKit", category: AppLogger.healthKit)

            // Process all samples (preserve multiple entries per day for historical accuracy)
            self?.processHistoricalWeightSamples(samples, completion: completion)
        }

        healthStore.execute(query)
    }

    /// Process weight samples for historical import (preserves all entries)
    /// Unlike regular sync, historical import preserves multiple entries per day for data completeness
    private func processHistoricalWeightSamples(_ samples: [HKQuantitySample], completion: @escaping ([WeightEntry]) -> Void) {
        // For historical import, preserve ALL entries (don't group by day)
        // This gives users complete historical accuracy as requested

        var weightEntries: [WeightEntry] = []
        let dispatchGroup = DispatchGroup()

        for sample in samples {
            dispatchGroup.enter()

            let weightInPounds = sample.quantity.doubleValue(for: HKUnit.pound())

            // Fetch BMI and body fat for this specific timestamp if available
            fetchBMIAndBodyFat(for: sample.startDate) { bmi, bodyFat in
                // INDUSTRY STANDARD: Detect actual data source (Renpho, Apple Health, etc.)
                let actualSource = self.detectWeightSource(from: sample)
                let entry = WeightEntry(
                    date: sample.startDate,
                    weight: weightInPounds,
                    bmi: bmi,
                    bodyFat: bodyFat,
                    source: actualSource,
                    healthKitUUID: sample.uuid  // Store UUID for precise deletion (Apple best practice)
                )
                weightEntries.append(entry)
                dispatchGroup.leave()
            }
        }

        dispatchGroup.notify(queue: .main) {
            // Sort by date (most recent first) and return complete historical dataset
            let sortedEntries = weightEntries.sorted { $0.date > $1.date }
            AppLogger.info("Processed \(sortedEntries.count) historical weight entries", category: AppLogger.healthKit)
            completion(sortedEntries)
        }
    }

    private func fetchBMIAndBodyFat(for date: Date, completion: @escaping (Double?, Double?) -> Void) {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)

        var bmi: Double?
        var bodyFat: Double?
        let group = DispatchGroup()

        // Fetch BMI
        if let bmiType = HKObjectType.quantityType(forIdentifier: .bodyMassIndex) {
            group.enter()
            let bmiQuery = HKSampleQuery(sampleType: bmiType, predicate: predicate, limit: 1, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]) { query, results, error in
                if let sample = results?.first as? HKQuantitySample {
                    bmi = sample.quantity.doubleValue(for: HKUnit.count())
                }
                group.leave()
            }
            healthStore.execute(bmiQuery)
        }

        // Fetch Body Fat Percentage
        if let bodyFatType = HKObjectType.quantityType(forIdentifier: .bodyFatPercentage) {
            group.enter()
            let bodyFatQuery = HKSampleQuery(sampleType: bodyFatType, predicate: predicate, limit: 1, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]) { query, results, error in
                if let sample = results?.first as? HKQuantitySample {
                    bodyFat = sample.quantity.doubleValue(for: HKUnit.percent()) * 100 // Convert to percentage
                }
                group.leave()
            }
            healthStore.execute(bodyFatQuery)
        }

        group.notify(queue: .main) {
            completion(bmi, bodyFat)
        }
    }

    // MARK: - Write Weight Data

    func saveWeight(weight: Double, bmi: Double? = nil, bodyFat: Double? = nil, date: Date = Date(), completion: @escaping (Bool, Error?) -> Void) {

        guard let weightType = HKObjectType.quantityType(forIdentifier: .bodyMass) else {
            completion(false, NSError(domain: "HealthKit", code: 2, userInfo: [NSLocalizedDescriptionKey: "Unable to access weight type"]))
            return
        }

        let weightQuantity = HKQuantity(unit: HKUnit.pound(), doubleValue: weight)
        let weightSample = HKQuantitySample(type: weightType, quantity: weightQuantity, start: date, end: date)

        var samplesToSave: [HKSample] = [weightSample]

        // Add BMI if provided
        if let bmi = bmi, let bmiType = HKObjectType.quantityType(forIdentifier: .bodyMassIndex) {
            let bmiQuantity = HKQuantity(unit: HKUnit.count(), doubleValue: bmi)
            let bmiSample = HKQuantitySample(type: bmiType, quantity: bmiQuantity, start: date, end: date)
            samplesToSave.append(bmiSample)
        }

        // Add Body Fat Percentage if provided
        if let bodyFat = bodyFat, let bodyFatType = HKObjectType.quantityType(forIdentifier: .bodyFatPercentage) {
            let bodyFatQuantity = HKQuantity(unit: HKUnit.percent(), doubleValue: bodyFat / 100) // Convert percentage to decimal
            let bodyFatSample = HKQuantitySample(type: bodyFatType, quantity: bodyFatQuantity, start: date, end: date)
            samplesToSave.append(bodyFatSample)
        }

        healthStore.save(samplesToSave) { [weak self] success, error in
            DispatchQueue.main.async {
                if let error = error {
                    // Apply industry-standard HKError handling
                    let errorMessage = self?.handleHealthKitError(error, operation: "save weight data") ?? "Unknown error"
                    AppLogger.error("Enhanced error handling for weight save: \(errorMessage)", category: AppLogger.healthKit, error: error)

                    // Update sync status with specific error
                    self?.updateWeightSyncStatus(success: false, error: errorMessage)
                    completion(false, error)
                } else {
                    AppLogger.info("Weight data saved successfully to HealthKit", category: AppLogger.weightTracking)
                    // Update sync status with success
                    self?.updateWeightSyncStatus(success: true)
                    completion(true, nil)
                }
            }
        }
    }

    // MARK: - Delete Weight Data

    /// Delete specific HealthKit sample by UUID (Apple best practice for precise deletion)
    /// Following Apple HealthKit Programming Guide: Always target specific samples by UUID
    /// Reference: https://developer.apple.com/documentation/healthkit/hksample/1614179-uuid
    func deleteWeightByUUID(_ uuid: UUID, completion: @escaping (Bool, Error?) -> Void) {
        guard let weightType = HKObjectType.quantityType(forIdentifier: .bodyMass) else {
            completion(false, NSError(domain: "HealthKit", code: 3, userInfo: [NSLocalizedDescriptionKey: "Unable to access weight type"]))
            return
        }

        // Use UUID predicate for precise deletion (Apple official pattern)
        let predicate = HKQuery.predicateForObjects(with: [uuid])
        let query = HKSampleQuery(sampleType: weightType, predicate: predicate, limit: 1, sortDescriptors: nil) { [weak self] query, results, error in
            guard let samples = results, error == nil, !samples.isEmpty else {
                DispatchQueue.main.async {
                    // Sample not found or already deleted - consider this success
                    AppLogger.info("HealthKit sample with UUID \(uuid) not found - may already be deleted", category: AppLogger.healthKit)
                    completion(true, nil)
                }
                return
            }

            // Delete the specific sample by UUID
            self?.healthStore.delete(samples) { success, error in
                DispatchQueue.main.async {
                    if success {
                        AppLogger.info("Successfully deleted HealthKit sample: \(uuid)", category: AppLogger.healthKit)
                    } else {
                        AppLogger.error("Failed to delete HealthKit sample: \(uuid)", category: AppLogger.healthKit, error: error)
                    }
                    completion(success, error)
                }
            }
        }
        healthStore.execute(query)
    }

    /// Find HealthKit sample UUID by date and weight for precise deletion
    /// Following Apple HealthKit Programming Guide: Query-then-delete pattern
    /// Used when entry doesn't have stored UUID (backward compatibility)
    func findWeightSampleUUID(date: Date, weight: Double, completion: @escaping (UUID?) -> Void) {
        guard let weightType = HKObjectType.quantityType(forIdentifier: .bodyMass) else {
            completion(nil)
            return
        }

        // Create wider date range (±30 minutes) to account for sync timing differences
        // Industry standard: Be more flexible with time matching for cross-app deletion
        let startDate = Calendar.current.date(byAdding: .minute, value: -30, to: date) ?? date
        let endDate = Calendar.current.date(byAdding: .minute, value: 30, to: date) ?? date
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)

        let query = HKSampleQuery(sampleType: weightType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { query, results, error in
            guard let samples = results as? [HKQuantitySample], error == nil else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }

            // Find closest matching sample by weight and time
            // Industry standard: More flexible matching for cross-app deletion
            let targetWeightInKg = weight * 0.453592 // Convert pounds to kg for HealthKit comparison
            let targetWeightInPounds = weight // Keep pounds for comparison too
            var closestSample: HKQuantitySample?
            var closestWeightDiff = Double.infinity
            var closestTimeDiff = Double.infinity

            AppLogger.info("Searching for sample: target=\(weight)lbs (\(targetWeightInKg)kg), date=\(date), found \(samples.count) samples", category: AppLogger.healthKit)

            for sample in samples {
                let sampleWeightKg = sample.quantity.doubleValue(for: HKUnit.gramUnit(with: .kilo))
                let sampleWeightLbs = sample.quantity.doubleValue(for: HKUnit.pound())
                let weightDiffLbs = abs(sampleWeightLbs - targetWeightInPounds)
                let timeDiff = abs(sample.startDate.timeIntervalSince(date))

                AppLogger.info("Comparing: sample=\(sampleWeightLbs)lbs (\(sampleWeightKg)kg), weightDiff=\(weightDiffLbs)lbs, timeDiff=\(timeDiff)s", category: AppLogger.healthKit)

                // More flexible weight matching: 0.2 lbs tolerance (industry standard for cross-app sync)
                if weightDiffLbs < 0.2 { // Within 0.2 lbs tolerance (more flexible)
                    if weightDiffLbs < closestWeightDiff || (weightDiffLbs == closestWeightDiff && timeDiff < closestTimeDiff) {
                        closestSample = sample
                        closestWeightDiff = weightDiffLbs
                        closestTimeDiff = timeDiff
                        AppLogger.info("New best match: weightDiff=\(weightDiffLbs)lbs, timeDiff=\(timeDiff)s", category: AppLogger.healthKit)
                    }
                }
            }

            DispatchQueue.main.async {
                if let foundSample = closestSample {
                    AppLogger.info("✅ Found matching HealthKit sample: UUID=\(foundSample.uuid), weight diff=\(closestWeightDiff)lbs, time diff=\(closestTimeDiff)s", category: AppLogger.healthKit)
                    completion(foundSample.uuid)
                } else {
                    AppLogger.warning("❌ No matching HealthKit sample found for date=\(date), weight=\(weight)lbs (searched \(samples.count) samples)", category: AppLogger.healthKit)
                    completion(nil)
                }
            }
        }

        healthStore.execute(query)
    }

    /// Legacy method - DEPRECATED: Use deleteWeightByUUID for precise deletion
    /// Kept for backward compatibility but should be replaced with UUID-based deletion
    @available(*, deprecated, message: "Use deleteWeightByUUID for precise deletion following Apple best practices")
    func deleteWeight(for date: Date, completion: @escaping (Bool, Error?) -> Void) {
        // For legacy compatibility, attempt to delete all samples on this date
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        guard let weightType = HKObjectType.quantityType(forIdentifier: .bodyMass) else {
            completion(false, NSError(domain: "HealthKit", code: 3, userInfo: [NSLocalizedDescriptionKey: "Unable to access weight type"]))
            return
        }

        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)

        let query = HKSampleQuery(sampleType: weightType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { [weak self] query, results, error in

            guard let samples = results, error == nil, !samples.isEmpty else {
                DispatchQueue.main.async {
                    completion(false, error)
                }
                return
            }

            self?.healthStore.delete(samples) { success, error in
                DispatchQueue.main.async {
                    completion(success, error)
                }
            }
        }

        healthStore.execute(query)
    }

    // MARK: - Read Water Data

    /// Fetches water data using HKAnchoredObjectQuery for efficient incremental sync
    /// Following Apple HealthKit Best Practices to prevent duplicates and improve performance
    func fetchWaterData(startDate: Date, endDate: Date = Date(), completion: @escaping ([(date: Date, amount: Double)]) -> Void) {
        guard let waterType = HKObjectType.quantityType(forIdentifier: .dietaryWater) else {
            completion([])
            return
        }

        // Load previously saved anchor for incremental sync
        let savedAnchor = loadAnchor(forKey: AnchorKeys.water)

        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)

        // Use HKAnchoredObjectQuery for better performance and duplicate prevention
        let query = HKAnchoredObjectQuery(
            type: waterType,
            predicate: predicate,
            anchor: savedAnchor,
            limit: HKObjectQueryNoLimit
        ) { [weak self] query, addedObjects, deletedObjects, newAnchor, error in

            guard error == nil else {
                if let error = error {
                    AppLogger.error("Error fetching water data with anchored query", category: AppLogger.healthKit, error: error)
                    self?.saveSyncError(for: SyncErrorKeys.water, error: error.localizedDescription)
                    // Record for production crash analysis
                    CrashReportManager.shared.recordHealthKitError(error, context: [
                        "operation": "fetchWaterData_anchored",
                        "startDate": startDate.description
                    ])
                }
                completion([])
                return
            }

            // Save the new anchor for next sync
            self?.saveAnchor(newAnchor, forKey: AnchorKeys.water)

            // Save sync timestamp and clear any previous errors
            self?.saveSyncTimestamp(for: SyncTimestampKeys.water)
            self?.saveSyncError(for: SyncErrorKeys.water, error: nil)

            // Process added samples
            guard let samples = addedObjects as? [HKQuantitySample] else {
                completion([])
                return
            }

            AppLogger.info("Fetched \(samples.count) water samples from HealthKit", category: AppLogger.healthKit)

            // Convert samples to date/amount tuples
            let waterData = samples.map { sample in
                let amountInOunces = sample.quantity.doubleValue(for: HKUnit.fluidOunceUS())
                return (date: sample.startDate, amount: amountInOunces)
            }

            DispatchQueue.main.async {
                completion(waterData)
            }
        }

        healthStore.execute(query)
    }

    // MARK: - Write Water Data

    func saveWater(amount: Double, date: Date = Date(), completion: @escaping (Bool, Error?) -> Void) {
        guard let waterType = HKObjectType.quantityType(forIdentifier: .dietaryWater) else {
            completion(false, NSError(domain: "HealthKit", code: 4, userInfo: [NSLocalizedDescriptionKey: "Unable to access water type"]))
            return
        }

        let waterQuantity = HKQuantity(unit: HKUnit.fluidOunceUS(), doubleValue: amount)
        let waterSample = HKQuantitySample(type: waterType, quantity: waterQuantity, start: date, end: date)

        healthStore.save(waterSample) { success, error in
            DispatchQueue.main.async {
                if let error = error {
                    AppLogger.error("Error saving water data", category: AppLogger.healthKit, error: error)
                } else {
                    AppLogger.info("Water data saved", category: AppLogger.healthKit)
                }
                completion(success, error)
            }
        }
    }

    // MARK: - Observer Query for Automatic Updates

    func startObserving(query: HKObserverQuery) {
        healthStore.execute(query)

        // Enable background delivery for weight updates
        guard let weightType = HKObjectType.quantityType(forIdentifier: .bodyMass) else { return }

        healthStore.enableBackgroundDelivery(for: weightType, frequency: .immediate) { success, error in
            if let error = error {
                AppLogger.error("Failed to enable background delivery", category: AppLogger.healthKit, error: error)
            } else if success {
                AppLogger.info("Background delivery enabled for weight data", category: AppLogger.healthKit)
            }
        }
    }

    func stopObserving(query: HKObserverQuery) {
        healthStore.stop(query)

        // Disable background delivery when no longer observing
        guard let weightType = HKObjectType.quantityType(forIdentifier: .bodyMass) else { return }

        healthStore.disableBackgroundDelivery(for: weightType) { success, error in
            if let error = error {
                AppLogger.error("Failed to disable background delivery", category: AppLogger.healthKit, error: error)
            }
        }
    }

    // MARK: - Sleep Tracking Methods

    func saveSleep(bedTime: Date, wakeTime: Date, completion: @escaping (Bool, Error?) -> Void) {
        let duration = (wakeTime.timeIntervalSince(bedTime)) / 3600
        AppLogger.info("Saving sleep to HealthKit - duration: \(String(format: "%.1fh", duration))", category: AppLogger.healthKit)

        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            AppLogger.error("Failed to get sleep type", category: AppLogger.healthKit)
            completion(false, nil)
            return
        }

        // Check authorization status
        let authStatus = healthStore.authorizationStatus(for: sleepType)
        AppLogger.info("Sleep authorization status: \(authStatus.rawValue)", category: AppLogger.healthKit)

        let sleepSample = HKCategorySample(
            type: sleepType,
            value: HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue,
            start: bedTime,
            end: wakeTime
        )

        healthStore.save(sleepSample) { success, error in
            DispatchQueue.main.async {
                if success {
                    AppLogger.info("Sleep data saved to HealthKit", category: AppLogger.healthKit)
                } else {
                    AppLogger.error("Sleep data save", category: AppLogger.healthKit, error: error)
                }
                completion(success, error)
            }
        }
    }

    func deleteSleep(bedTime: Date, wakeTime: Date, completion: @escaping (Bool, Error?) -> Void) {
        AppLogger.info("Deleting sleep from HealthKit", category: AppLogger.healthKit)

        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            AppLogger.error("Failed to get sleep type", category: AppLogger.healthKit)
            completion(false, nil)
            return
        }

        // Check authorization status
        let authStatus = healthStore.authorizationStatus(for: sleepType)
        AppLogger.info("Sleep authorization status: \(authStatus.rawValue)", category: AppLogger.healthKit)

        // Find the sample that matches these times
        let predicate = HKQuery.predicateForSamples(withStart: bedTime, end: wakeTime, options: .strictStartDate)
        AppLogger.info("Searching for matching HealthKit sleep sample", category: AppLogger.healthKit)

        let query = HKSampleQuery(
            sampleType: sleepType,
            predicate: predicate,
            limit: 1,
            sortDescriptors: nil
        ) { [weak self] _, samples, error in
            if let error = error {
                AppLogger.error("Sleep query error", category: AppLogger.healthKit, error: error)
                DispatchQueue.main.async {
                    completion(false, error)
                }
                return
            }

            guard let sample = samples?.first as? HKCategorySample else {
                AppLogger.warning("No matching sleep sample found in HealthKit", category: AppLogger.healthKit)
                DispatchQueue.main.async {
                    completion(false, nil)
                }
                return
            }

            AppLogger.info("Found matching sleep sample, deleting", category: AppLogger.healthKit)
            self?.healthStore.delete(sample) { success, error in
                DispatchQueue.main.async {
                    if success {
                        AppLogger.info("Sleep data deleted from HealthKit", category: AppLogger.healthKit)
                    } else {
                        AppLogger.error("Sleep data deletion", category: AppLogger.healthKit, error: error)
                    }
                    completion(success, error)
                }
            }
        }

        healthStore.execute(query)
    }

    /// Fetches sleep data using HKAnchoredObjectQuery for efficient incremental sync
    /// Following Apple HealthKit Best Practices to prevent duplicates and improve performance
    func fetchSleepData(startDate: Date, completion: @escaping ([SleepEntry]) -> Void) {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            AppLogger.error("Failed to create sleep analysis type", category: AppLogger.healthKit)
            // Record critical HealthKit setup failure
            let error = NSError(domain: "HealthKit", code: 1001, userInfo: [
                NSLocalizedDescriptionKey: "Failed to create sleep analysis type"
            ])
            CrashReportManager.shared.recordHealthKitError(error, context: [
                "operation": "createSleepAnalysisType"
            ])
            completion([])
            return
        }

        // Load previously saved anchor for incremental sync
        let savedAnchor = loadAnchor(forKey: AnchorKeys.sleep)

        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: .strictStartDate)

        // Use HKAnchoredObjectQuery for better performance and duplicate prevention
        let query = HKAnchoredObjectQuery(
            type: sleepType,
            predicate: predicate,
            anchor: savedAnchor,
            limit: HKObjectQueryNoLimit
        ) { [weak self] query, addedObjects, deletedObjects, newAnchor, error in

            guard error == nil else {
                if let error = error {
                    AppLogger.error("Error fetching sleep data with anchored query", category: AppLogger.healthKit, error: error)
                    self?.saveSyncError(for: SyncErrorKeys.sleep, error: error.localizedDescription)
                }
                DispatchQueue.main.async {
                    completion([])
                }
                return
            }

            // Save the new anchor for next sync
            self?.saveAnchor(newAnchor, forKey: AnchorKeys.sleep)

            // Save sync timestamp and clear any previous errors
            self?.saveSyncTimestamp(for: SyncTimestampKeys.sleep)
            self?.saveSyncError(for: SyncErrorKeys.sleep, error: nil)

            // Process added samples
            guard let samples = addedObjects as? [HKCategorySample] else {
                DispatchQueue.main.async {
                    completion([])
                }
                return
            }

            AppLogger.info("Fetched \(samples.count) sleep samples from HealthKit", category: AppLogger.healthKit)

            // Convert HKCategorySamples to SleepEntry objects
            let sleepEntries = samples.map { sample in
                SleepEntry(
                    bedTime: sample.startDate,
                    wakeTime: sample.endDate,
                    quality: nil,
                    source: .healthKit
                )
            }

            DispatchQueue.main.async {
                completion(sleepEntries)
            }
        }

        healthStore.execute(query)
    }

    func startObservingSleep(query: HKObserverQuery) {
        healthStore.execute(query)

        // Enable background delivery
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return }

        healthStore.enableBackgroundDelivery(for: sleepType, frequency: .immediate) { success, error in
            if let error = error {
                AppLogger.error("Failed to enable sleep background delivery", category: AppLogger.healthKit, error: error)
            }
        }
    }

    func stopObservingSleep(query: HKObserverQuery) {
        healthStore.stop(query)

        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return }

        healthStore.disableBackgroundDelivery(for: sleepType) { success, error in
            if let error = error {
                AppLogger.error("Failed to disable sleep background delivery", category: AppLogger.healthKit, error: error)
            }
        }
    }

    // MARK: - Fasting Tracking Methods

    /// Saves a completed fasting session to HealthKit as a workout
    /// Industry Standard: Fasting apps store fasting sessions as low-intensity workouts
    /// Reference: HKWorkoutActivityType.other is used for non-traditional activities
    /// Note: Explicit duration parameter is intentional for accurate Health app chart display
    func saveFastingSession(_ session: FastingSession, completion: @escaping (Bool, Error?) -> Void) {
        guard session.isComplete else {
            AppLogger.warning("Attempted to save incomplete fasting session to HealthKit", category: AppLogger.healthKit)
            completion(false, NSError(domain: "HealthKit", code: 5, userInfo: [NSLocalizedDescriptionKey: "Cannot save incomplete fasting session"]))
            return
        }

        guard let endTime = session.endTime else {
            AppLogger.warning("Fasting session missing end time", category: AppLogger.healthKit)
            completion(false, NSError(domain: "HealthKit", code: 5, userInfo: [NSLocalizedDescriptionKey: "Fasting session missing end time"]))
            return
        }

        let duration = session.duration
        let durationHours = duration / 3600
        AppLogger.info("Saving fasting session to HealthKit - duration: \(String(format: "%.1fh", durationHours))", category: AppLogger.healthKit)

        // SOLUTION: Normalize workout times to prevent Health app from splitting across calendar days
        // Per Apple Health behavior: Workouts spanning midnight get split in chart view
        // Strategy: Store workout on the END DATE at noon, with duration properly set
        // This keeps the entire workout within a single calendar day for consistent chart display
        // Reference: Apple Health splits multi-day activities (confirmed via user testing)

        let calendar = Calendar.current
        let endDateOnly = calendar.startOfDay(for: endTime) // Midnight of end date
        let noonOnEndDate = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: endDateOnly)!

        // Center the workout around noon on the end date
        let normalizedStart = noonOnEndDate.addingTimeInterval(duration / -2) // Start 8 hours before noon (4 AM for 16h fast)
        let normalizedEnd = noonOnEndDate.addingTimeInterval(duration / 2) // End 8 hours after noon (8 PM for 16h fast)

        // Create workout with metadata - preserve REAL times in metadata for accuracy
        var metadata: [String: Any] = [
            HKMetadataKeyWorkoutBrandName: "Fast LIFe",
            "FastingDuration": duration,
            "FastingGoal": session.goalHours ?? 0,
            "ActualStartTime": session.startTime.timeIntervalSince1970, // Store real start time
            "ActualEndTime": endTime.timeIntervalSince1970 // Store real end time
        ]

        // Add eating window if available
        if let eatingWindow = session.eatingWindowDuration {
            metadata["EatingWindowDuration"] = eatingWindow
        }

        // Create workout using HKWorkoutBuilder (iOS 17+ recommended approach)
        // This replaces the deprecated HKWorkout initializer
        // Reference: https://developer.apple.com/documentation/healthkit/hkworkoutbuilder

        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .other // Used for non-traditional activities like fasting

        let builder = HKWorkoutBuilder(healthStore: healthStore, configuration: configuration, device: .local())

        // Begin the workout collection
        builder.beginCollection(withStart: normalizedStart) { success, error in
            guard success else {
                DispatchQueue.main.async {
                    AppLogger.error("Workout builder begin collection", category: AppLogger.healthKit, error: error)
                    completion(false, error)
                }
                return
            }

            // End the workout collection
            builder.endCollection(withEnd: normalizedEnd) { success, error in
                guard success else {
                    DispatchQueue.main.async {
                        AppLogger.error("Workout builder end collection", category: AppLogger.healthKit, error: error)
                        completion(false, error)
                    }
                    return
                }

                // Add metadata to the builder
                builder.addMetadata(metadata) { success, error in
                    guard success else {
                        DispatchQueue.main.async {
                            AppLogger.error("Workout builder add metadata", category: AppLogger.healthKit, error: error)
                            completion(false, error)
                        }
                        return
                    }

                    // Finish the workout
                    builder.finishWorkout { workout, error in
                        DispatchQueue.main.async {
                            if workout != nil {
                                AppLogger.info("Fasting session saved to HealthKit", category: AppLogger.healthKit)
                                completion(true, nil)
                            } else {
                                AppLogger.error("Workout builder finish", category: AppLogger.healthKit, error: error)
                                completion(false, error)
                            }
                        }
                    }
                }
            }
        }
    }

    /// Deletes a fasting session from HealthKit
    func deleteFastingSession(_ session: FastingSession, completion: @escaping (Bool, Error?) -> Void) {
        guard let endTime = session.endTime else {
            AppLogger.warning("Cannot delete fasting session without end time", category: AppLogger.healthKit)
            completion(false, nil)
            return
        }

        AppLogger.info("Deleting fasting session from HealthKit", category: AppLogger.healthKit)

        let workoutType = HKObjectType.workoutType()
        let predicate = HKQuery.predicateForSamples(withStart: session.startTime, end: endTime, options: .strictStartDate)

        let query = HKSampleQuery(
            sampleType: workoutType,
            predicate: predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: nil
        ) { [weak self] _, samples, error in
            if let error = error {
                AppLogger.error("Fasting session query error", category: AppLogger.healthKit, error: error)
                DispatchQueue.main.async {
                    completion(false, error)
                }
                return
            }

            // Filter for Fast LIFe workouts only
            guard let workouts = samples as? [HKWorkout],
                  let fastingWorkout = workouts.first(where: { workout in
                      workout.metadata?[HKMetadataKeyWorkoutBrandName] as? String == "Fast LIFe"
                  }) else {
                AppLogger.warning("No matching fasting workout found in HealthKit", category: AppLogger.healthKit)
                DispatchQueue.main.async {
                    completion(false, nil)
                }
                return
            }

            AppLogger.info("Found matching fasting workout, deleting", category: AppLogger.healthKit)
            self?.healthStore.delete(fastingWorkout) { success, error in
                DispatchQueue.main.async {
                    if success {
                        AppLogger.info("Fasting session deleted from HealthKit", category: AppLogger.healthKit)
                    } else {
                        AppLogger.error("Fasting session deletion", category: AppLogger.healthKit, error: error)
                    }
                    completion(success, error)
                }
            }
        }

        healthStore.execute(query)
    }

    /// Fetches all fasting sessions (workouts marked as Fast LIFe) using HKAnchoredObjectQuery
    /// Following Apple HealthKit Best Practices to prevent duplicates and improve performance
    func fetchFastingData(startDate: Date, completion: @escaping ([FastingSession]) -> Void) {
        let workoutType = HKObjectType.workoutType()

        // Load previously saved anchor for incremental sync
        let savedAnchor = loadAnchor(forKey: AnchorKeys.fasting)

        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: .strictStartDate)

        // Use HKAnchoredObjectQuery for better performance and duplicate prevention
        let query = HKAnchoredObjectQuery(
            type: workoutType,
            predicate: predicate,
            anchor: savedAnchor,
            limit: HKObjectQueryNoLimit
        ) { [weak self] query, addedObjects, deletedObjects, newAnchor, error in

            guard error == nil else {
                if let error = error {
                    AppLogger.error("Error fetching fasting workout data with anchored query", category: AppLogger.healthKit, error: error)
                    self?.saveSyncError(for: SyncErrorKeys.fasting, error: error.localizedDescription)
                }
                DispatchQueue.main.async {
                    completion([])
                }
                return
            }

            // Save the new anchor for next sync
            self?.saveAnchor(newAnchor, forKey: AnchorKeys.fasting)

            // Save sync timestamp and clear any previous errors
            self?.saveSyncTimestamp(for: SyncTimestampKeys.fasting)
            self?.saveSyncError(for: SyncErrorKeys.fasting, error: nil)

            // Process added samples
            guard let workouts = addedObjects as? [HKWorkout] else {
                DispatchQueue.main.async {
                    completion([])
                }
                return
            }

            AppLogger.info("Fetched \(workouts.count) workout samples from HealthKit", category: AppLogger.healthKit)

            // Filter for Fast LIFe fasting workouts only
            let fastingSessions = workouts.compactMap { workout -> FastingSession? in
                // Only return workouts created by Fast LIFe (identified by metadata brand name)
                guard workout.metadata?[HKMetadataKeyWorkoutBrandName] as? String == "Fast LIFe" else {
                    return nil
                }

                // Extract optional metadata (goal hours and eating window)
                let goalHours = workout.metadata?["FastingGoal"] as? Double
                let eatingWindow = workout.metadata?["EatingWindowDuration"] as? TimeInterval

                // FastingSession calculates duration automatically from startDate/endDate
                // No need to read FastingDuration from metadata since it's a computed property
                return FastingSession(
                    startTime: workout.startDate,
                    endTime: workout.endDate,
                    goalHours: goalHours,
                    eatingWindowDuration: eatingWindow
                )
            }

            AppLogger.info("Filtered to \(fastingSessions.count) Fast LIFe fasting sessions", category: AppLogger.healthKit)

            DispatchQueue.main.async {
                completion(fastingSessions)
            }
        }

        healthStore.execute(query)
    }

    // MARK: - Service Layer Integration

    /// Expose health store for HealthKitService integration (internal use only)
    /// Following Apple Swift guidelines for controlled access to private properties
    func getHealthStore() -> HKHealthStore {
        return healthStore
    }
}

// MARK: - HKError Handling Extension
// Following Apple HealthKit Programming Guide: Handling Errors When Working with HealthKit
// Reference: https://developer.apple.com/documentation/healthkit/handling_errors_when_working_with_healthkit

extension HealthKitManager {

    /// Handles HKError cases following Apple's best practices
    /// Returns user-friendly error messages and logs technical details
    private func handleHealthKitError(_ error: Error, operation: String) -> String {
        // Cast to HKError to access specific error cases
        if let hkError = error as? HKError {
            // Use raw values to avoid compilation issues with iOS version differences
            switch hkError.code.rawValue {
            case 4: // HKError.errorAuthorizationDenied
                AppLogger.error("HealthKit authorization denied for \(operation)", category: AppLogger.healthKit, error: hkError)
                return "Permission denied. Please check Settings > Health > Data Access & Devices."

            case 5: // HKError.errorDatabaseInaccessible
                AppLogger.error("HealthKit database inaccessible for \(operation)", category: AppLogger.healthKit, error: hkError)
                return "Health data is temporarily unavailable. Please unlock your device and try again."

            case 3: // HKError.errorAuthorizationNotDetermined
                AppLogger.error("HealthKit authorization not determined for \(operation)", category: AppLogger.healthKit, error: hkError)
                return "Health permissions not set. Please enable access in Settings."

            case 11: // HKError.errorNoData
                AppLogger.warning("No health data available for \(operation)", category: AppLogger.healthKit)
                return "No data available for this time period."

            case 2: // HKError.errorInvalidArgument
                AppLogger.error("Invalid argument in HealthKit \(operation)", category: AppLogger.healthKit, error: hkError)
                return "Invalid data format. Please try again."

            default:
                AppLogger.error("HealthKit error (\(hkError.code.rawValue)) for \(operation): \(hkError.localizedDescription)", category: AppLogger.healthKit, error: hkError)
                return "Health data sync encountered an error. Please try again."
            }
        } else {
            // Non-HKError case (network, etc.)
            AppLogger.error("Non-HealthKit error for \(operation)", category: AppLogger.healthKit, error: error)
            return error.localizedDescription
        }
    }

    /// Checks if an error is recoverable and suggests retry
    private func isRecoverableError(_ error: Error) -> Bool {
        if let hkError = error as? HKError {
            switch hkError.code.rawValue {
            case 5: // HKError.errorDatabaseInaccessible
                return true // User can unlock device
            case 11: // HKError.errorNoData
                return true // Data might become available
            case 4: // HKError.errorAuthorizationDenied
                return false // Requires user settings change
            default:
                return true // Most errors are recoverable
            }
        }
        return true // Assume recoverable for non-HKErrors
    }
}
