import Foundation
import HealthKit

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
    func requestWeightAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        AppLogger.info("Requesting authorization for Weight", category: AppLogger.healthKit)
        guard HKHealthStore.isHealthDataAvailable() else {
            AppLogger.warning("HealthKit not available on this device", category: AppLogger.healthKit)
            completion(false, NSError(domain: "HealthKit", code: 1, userInfo: [NSLocalizedDescriptionKey: "HealthKit is not available on this device"]))
            return
        }

        // Weight-related types only
        let readTypes: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .bodyMass)!,
            HKObjectType.quantityType(forIdentifier: .bodyMassIndex)!,
            HKObjectType.quantityType(forIdentifier: .bodyFatPercentage)!
        ]

        let writeTypes: Set<HKSampleType> = [
            HKObjectType.quantityType(forIdentifier: .bodyMass)!,
            HKObjectType.quantityType(forIdentifier: .bodyMassIndex)!,
            HKObjectType.quantityType(forIdentifier: .bodyFatPercentage)!
        ]

        AppLogger.info("Requesting authorization for weight tracking", category: AppLogger.healthKit)
        AppLogger.info("DEBUG: readTypes count: \(readTypes.count), writeTypes count: \(writeTypes.count)", category: AppLogger.healthKit)
        AppLogger.info("DEBUG: readTypes: \(readTypes)", category: AppLogger.healthKit)
        AppLogger.info("DEBUG: writeTypes: \(writeTypes)", category: AppLogger.healthKit)

        healthStore.requestAuthorization(toShare: writeTypes, read: readTypes) { [weak self] success, error in
            DispatchQueue.main.async {
                AppLogger.info("DEBUG: Authorization callback - success: \(success), error: \(String(describing: error))", category: AppLogger.healthKit)
                if success {
                    AppLogger.info("Weight authorization granted", category: AppLogger.healthKit)
                    self?.checkAuthorizationStatus()
                } else {
                    AppLogger.info("Weight authorization denied", category: AppLogger.healthKit)
                    if let error = error {
                        AppLogger.error("Weight authorization error", category: AppLogger.healthKit, error: error)
                    } else {
                        AppLogger.warning("Weight authorization denied with no error - this means Apple dialog never appeared", category: AppLogger.healthKit)
                    }
                }
                completion(success, error)
            }
        }
    }

    /// Request authorization for hydration tracking only (dietary water)
    func requestHydrationAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        AppLogger.info("Requesting authorization for Hydration", category: AppLogger.healthKit)
        guard HKHealthStore.isHealthDataAvailable() else {
            AppLogger.warning("HealthKit not available on this device", category: AppLogger.healthKit)
            completion(false, NSError(domain: "HealthKit", code: 1, userInfo: [NSLocalizedDescriptionKey: "HealthKit is not available on this device"]))
            return
        }

        // Hydration types only
        let readTypes: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .dietaryWater)!
        ]

        let writeTypes: Set<HKSampleType> = [
            HKObjectType.quantityType(forIdentifier: .dietaryWater)!
        ]

        AppLogger.info("Requesting authorization for hydration tracking", category: AppLogger.healthKit)
        healthStore.requestAuthorization(toShare: writeTypes, read: readTypes) { [weak self] success, error in
            DispatchQueue.main.async {
                if success {
                    AppLogger.info("Hydration authorization granted", category: AppLogger.healthKit)
                    self?.checkAuthorizationStatus()
                } else {
                    AppLogger.info("Hydration authorization denied", category: AppLogger.healthKit)
                    if let error = error {
                        AppLogger.error("Hydration authorization error", category: AppLogger.healthKit, error: error)
                    }
                }
                completion(success, error)
            }
        }
    }

    /// Request authorization for sleep tracking only (sleep analysis)
    func requestSleepAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        AppLogger.info("Requesting authorization for Sleep", category: AppLogger.healthKit)
        guard HKHealthStore.isHealthDataAvailable() else {
            AppLogger.warning("HealthKit not available on this device", category: AppLogger.healthKit)
            completion(false, NSError(domain: "HealthKit", code: 1, userInfo: [NSLocalizedDescriptionKey: "HealthKit is not available on this device"]))
            return
        }

        // Sleep types only
        let readTypes: Set<HKObjectType> = [
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        ]

        let writeTypes: Set<HKSampleType> = [
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        ]

        AppLogger.info("Requesting authorization for sleep tracking", category: AppLogger.healthKit)
        healthStore.requestAuthorization(toShare: writeTypes, read: readTypes) { [weak self] success, error in
            DispatchQueue.main.async {
                if success {
                    AppLogger.info("Sleep authorization granted", category: AppLogger.healthKit)
                    self?.checkAuthorizationStatus()
                } else {
                    AppLogger.info("Sleep authorization denied", category: AppLogger.healthKit)
                    if let error = error {
                        AppLogger.error("Sleep authorization error", category: AppLogger.healthKit, error: error)
                    }
                }
                completion(success, error)
            }
        }
    }

    /// Request authorization for fasting tracking (stored as workouts in HealthKit)
    func requestFastingAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        AppLogger.info("Requesting authorization for Fasting", category: AppLogger.healthKit)
        guard HKHealthStore.isHealthDataAvailable() else {
            AppLogger.warning("HealthKit not available on this device", category: AppLogger.healthKit)
            completion(false, NSError(domain: "HealthKit", code: 1, userInfo: [NSLocalizedDescriptionKey: "HealthKit is not available on this device"]))
            return
        }

        // Fasting sessions are stored as workouts
        // Apple Health doesn't have a dedicated fasting category, so we use workouts
        // This is the industry-standard approach used by major fasting apps
        let readTypes: Set<HKObjectType> = [
            HKObjectType.workoutType()
        ]

        let writeTypes: Set<HKSampleType> = [
            HKObjectType.workoutType()
        ]

        AppLogger.info("Requesting authorization for fasting tracking (as workouts)", category: AppLogger.healthKit)
        healthStore.requestAuthorization(toShare: writeTypes, read: readTypes) { [weak self] success, error in
            DispatchQueue.main.async {
                if success {
                    AppLogger.info("Fasting authorization granted", category: AppLogger.healthKit)
                    self?.checkAuthorizationStatus()
                } else {
                    AppLogger.info("Fasting authorization denied", category: AppLogger.healthKit)
                    if let error = error {
                        AppLogger.error("Fasting authorization error", category: AppLogger.healthKit, error: error)
                    }
                }
                completion(success, error)
            }
        }
    }

    // MARK: - Legacy Authorization (For "Sync All" Features Only)
    // NOTE: This method requests ALL permissions at once
    // USAGE: Only use for "Sync All" features where requesting all permissions simultaneously is intentional
    // For individual features, use domain-specific methods: requestWeightAuthorization(), requestHydrationAuthorization(), requestSleepAuthorization()
    // Reference: https://developer.apple.com/documentation/healthkit/protecting_user_privacy
    func requestAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            completion(false, NSError(domain: "HealthKit", code: 1, userInfo: [NSLocalizedDescriptionKey: "HealthKit is not available on this device"]))
            return
        }

        // Types to read from HealthKit
        let readTypes: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .bodyMass)!,
            HKObjectType.quantityType(forIdentifier: .bodyMassIndex)!,
            HKObjectType.quantityType(forIdentifier: .bodyFatPercentage)!,
            HKObjectType.quantityType(forIdentifier: .dietaryWater)!,
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
            HKObjectType.workoutType() // Required for fasting sessions
        ]

        // Types to write to HealthKit
        let writeTypes: Set<HKSampleType> = [
            HKObjectType.quantityType(forIdentifier: .bodyMass)!,
            HKObjectType.quantityType(forIdentifier: .bodyMassIndex)!,
            HKObjectType.quantityType(forIdentifier: .bodyFatPercentage)!,
            HKObjectType.quantityType(forIdentifier: .dietaryWater)!,
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
            HKObjectType.workoutType() // Required for fasting sessions
        ]

        healthStore.requestAuthorization(toShare: writeTypes, read: readTypes) { [weak self] success, error in
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

    // MARK: - Read Weight Data

    /// Fetches weight data using HKAnchoredObjectQuery for efficient incremental sync
    /// Following Apple HealthKit Best Practices to prevent duplicates and improve performance
    /// Reference: https://developer.apple.com/documentation/healthkit/hkanchoredobjectquery
    func fetchWeightData(startDate: Date, endDate: Date = Date(), completion: @escaping ([WeightEntry]) -> Void) {
        fetchWeightDataAnchored(startDate: startDate, endDate: endDate, completion: completion)
    }

    private func fetchWeightDataAnchored(startDate: Date, endDate: Date = Date(), completion: @escaping ([WeightEntry]) -> Void) {
        guard let weightType = HKObjectType.quantityType(forIdentifier: .bodyMass) else {
            completion([])
            return
        }

        // Load previously saved anchor for incremental sync
        let savedAnchor = loadAnchor(forKey: AnchorKeys.weight)

        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)

        // Use HKAnchoredObjectQuery instead of HKSampleQuery for better performance and duplicate prevention
        let query = HKAnchoredObjectQuery(
            type: weightType,
            predicate: predicate,
            anchor: savedAnchor,
            limit: HKObjectQueryNoLimit
        ) { [weak self] query, addedObjects, deletedObjects, newAnchor, error in

            guard error == nil else {
                if let error = error {
                    AppLogger.error("Error fetching weight data with anchored query", category: AppLogger.healthKit, error: error)
                    // Save error state for UI display
                    self?.saveSyncError(for: SyncErrorKeys.weight, error: error.localizedDescription)
                    // Record for production crash analysis
                    CrashReportManager.shared.recordHealthKitError(error, context: [
                        "operation": "fetchWeightData_anchored",
                        "startDate": startDate.description
                    ])
                }
                completion([])
                return
            }

            // Save the new anchor for next sync
            self?.saveAnchor(newAnchor, forKey: AnchorKeys.weight)

            // Save sync timestamp and clear any previous errors
            self?.saveSyncTimestamp(for: SyncTimestampKeys.weight)
            self?.saveSyncError(for: SyncErrorKeys.weight, error: nil)

            // Process added samples
            guard let samples = addedObjects as? [HKQuantitySample] else {
                completion([])
                return
            }

            AppLogger.info("Fetched \(samples.count) weight samples from HealthKit", category: AppLogger.healthKit)

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

            guard let samples = results as? [HKQuantitySample], error == nil else {
                if let error = error {
                    AppLogger.error("Error fetching weight data", category: AppLogger.healthKit, error: error)
                }
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
                    let entry = WeightEntry(
                        date: sample.startDate,
                        weight: weightInPounds,
                        bmi: bmi,
                        bodyFat: bodyFat,
                        source: .healthKit
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
            fetchBMIAndBodyFat(for: date) { bmi, bodyFat in
                let entry = WeightEntry(
                    date: sample.startDate,
                    weight: weightInPounds,
                    bmi: bmi,
                    bodyFat: bodyFat,
                    source: .healthKit
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

        healthStore.save(samplesToSave) { success, error in
            DispatchQueue.main.async {
                if let error = error {
                    AppLogger.error("Error saving weight data", category: AppLogger.healthKit, error: error)
                } else {
                    AppLogger.info("Weight data saved", category: AppLogger.weightTracking)
                }
                completion(success, error)
            }
        }
    }

    // MARK: - Delete Weight Data

    func deleteWeight(for date: Date, completion: @escaping (Bool, Error?) -> Void) {
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
}
