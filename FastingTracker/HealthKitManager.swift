import Foundation
import HealthKit

class HealthKitManager: ObservableObject {
    static let shared = HealthKitManager()

    private let healthStore = HKHealthStore()
    @Published var isAuthorized = false

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
            Log.warning("HealthKit is not available on this device", category: .healthkit)
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
        Log.logAuthRequest("Weight", category: .healthkit)
        guard HKHealthStore.isHealthDataAvailable() else {
            Log.warning("HealthKit not available on this device", category: .healthkit)
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

        Log.info("Requesting authorization for weight tracking", category: .healthkit)
        healthStore.requestAuthorization(toShare: writeTypes, read: readTypes) { [weak self] success, error in
            DispatchQueue.main.async {
                if success {
                    Log.logAuthResult("Weight", granted: true, category: .healthkit)
                    self?.checkAuthorizationStatus()
                } else {
                    Log.logAuthResult("Weight", granted: false, category: .healthkit)
                    if let error = error {
                        Log.error("Weight authorization error", category: .healthkit, error: error)
                    }
                }
                completion(success, error)
            }
        }
    }

    /// Request authorization for hydration tracking only (dietary water)
    func requestHydrationAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        Log.logAuthRequest("Hydration", category: .healthkit)
        guard HKHealthStore.isHealthDataAvailable() else {
            Log.warning("HealthKit not available on this device", category: .healthkit)
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

        Log.info("Requesting authorization for hydration tracking", category: .healthkit)
        healthStore.requestAuthorization(toShare: writeTypes, read: readTypes) { [weak self] success, error in
            DispatchQueue.main.async {
                if success {
                    Log.logAuthResult("Hydration", granted: true, category: .healthkit)
                    self?.checkAuthorizationStatus()
                } else {
                    Log.logAuthResult("Hydration", granted: false, category: .healthkit)
                    if let error = error {
                        Log.error("Hydration authorization error", category: .healthkit, error: error)
                    }
                }
                completion(success, error)
            }
        }
    }

    /// Request authorization for sleep tracking only (sleep analysis)
    func requestSleepAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        Log.logAuthRequest("Sleep", category: .healthkit)
        guard HKHealthStore.isHealthDataAvailable() else {
            Log.warning("HealthKit not available on this device", category: .healthkit)
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

        Log.info("Requesting authorization for sleep tracking", category: .healthkit)
        healthStore.requestAuthorization(toShare: writeTypes, read: readTypes) { [weak self] success, error in
            DispatchQueue.main.async {
                if success {
                    Log.logAuthResult("Sleep", granted: true, category: .healthkit)
                    self?.checkAuthorizationStatus()
                } else {
                    Log.logAuthResult("Sleep", granted: false, category: .healthkit)
                    if let error = error {
                        Log.error("Sleep authorization error", category: .healthkit, error: error)
                    }
                }
                completion(success, error)
            }
        }
    }

    /// Request authorization for fasting tracking (stored as workouts in HealthKit)
    func requestFastingAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        Log.logAuthRequest("Fasting", category: .healthkit)
        guard HKHealthStore.isHealthDataAvailable() else {
            Log.warning("HealthKit not available on this device", category: .healthkit)
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

        Log.info("Requesting authorization for fasting tracking (as workouts)", category: .healthkit)
        healthStore.requestAuthorization(toShare: writeTypes, read: readTypes) { [weak self] success, error in
            DispatchQueue.main.async {
                if success {
                    Log.logAuthResult("Fasting", granted: true, category: .healthkit)
                    self?.checkAuthorizationStatus()
                } else {
                    Log.logAuthResult("Fasting", granted: false, category: .healthkit)
                    if let error = error {
                        Log.error("Fasting authorization error", category: .healthkit, error: error)
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
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        ]

        // Types to write to HealthKit
        let writeTypes: Set<HKSampleType> = [
            HKObjectType.quantityType(forIdentifier: .bodyMass)!,
            HKObjectType.quantityType(forIdentifier: .bodyMassIndex)!,
            HKObjectType.quantityType(forIdentifier: .bodyFatPercentage)!,
            HKObjectType.quantityType(forIdentifier: .dietaryWater)!,
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        ]

        healthStore.requestAuthorization(toShare: writeTypes, read: readTypes) { [weak self] success, error in
            DispatchQueue.main.async {
                self?.isAuthorized = success
                completion(success, error)
            }
        }
    }

    // MARK: - Read Weight Data

    func fetchWeightData(startDate: Date, endDate: Date = Date(), completion: @escaping ([WeightEntry]) -> Void) {
        guard let weightType = HKObjectType.quantityType(forIdentifier: .bodyMass) else {
            completion([])
            return
        }

        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        let query = HKSampleQuery(sampleType: weightType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { [weak self] query, results, error in

            guard let samples = results as? [HKQuantitySample], error == nil else {
                if let error = error {
                    Log.error("Error fetching weight data", category: .healthkit, error: error)
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
                    Log.error("Error saving weight data", category: .healthkit, error: error)
                } else {
                    Log.logSuccess("Weight data saved", category: .weight)
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

    func fetchWaterData(startDate: Date, endDate: Date = Date(), completion: @escaping ([(date: Date, amount: Double)]) -> Void) {
        guard let waterType = HKObjectType.quantityType(forIdentifier: .dietaryWater) else {
            completion([])
            return
        }

        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        let query = HKSampleQuery(sampleType: waterType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { query, results, error in

            guard let samples = results as? [HKQuantitySample], error == nil else {
                if let error = error {
                    Log.error("Error fetching water data", category: .healthkit, error: error)
                }
                completion([])
                return
            }

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
                    Log.error("Error saving water data", category: .healthkit, error: error)
                } else {
                    Log.logSuccess("Water data saved", category: .hydration)
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
                Log.error("Failed to enable background delivery", category: .healthkit, error: error)
            } else if success {
                Log.info("Background delivery enabled for weight data", category: .healthkit)
            }
        }
    }

    func stopObserving(query: HKObserverQuery) {
        healthStore.stop(query)

        // Disable background delivery when no longer observing
        guard let weightType = HKObjectType.quantityType(forIdentifier: .bodyMass) else { return }

        healthStore.disableBackgroundDelivery(for: weightType) { success, error in
            if let error = error {
                Log.error("Failed to disable background delivery", category: .healthkit, error: error)
            }
        }
    }

    // MARK: - Sleep Tracking Methods

    func saveSleep(bedTime: Date, wakeTime: Date, completion: @escaping (Bool, Error?) -> Void) {
        let duration = (wakeTime.timeIntervalSince(bedTime)) / 3600
        Log.info("Saving sleep to HealthKit", category: .sleep, metadata: ["duration": String(format: "%.1fh", duration)])

        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            Log.error("Failed to get sleep type", category: .healthkit)
            completion(false, nil)
            return
        }

        // Check authorization status
        let authStatus = healthStore.authorizationStatus(for: sleepType)
        Log.debug("Sleep authorization status: \(authStatus.rawValue)", category: .healthkit)

        let sleepSample = HKCategorySample(
            type: sleepType,
            value: HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue,
            start: bedTime,
            end: wakeTime
        )

        healthStore.save(sleepSample) { success, error in
            DispatchQueue.main.async {
                if success {
                    Log.logSuccess("Sleep data saved to HealthKit", category: .sleep)
                } else {
                    Log.logFailure("Sleep data save", category: .sleep, error: error)
                }
                completion(success, error)
            }
        }
    }

    func deleteSleep(bedTime: Date, wakeTime: Date, completion: @escaping (Bool, Error?) -> Void) {
        Log.info("Deleting sleep from HealthKit", category: .sleep)

        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            Log.error("Failed to get sleep type", category: .healthkit)
            completion(false, nil)
            return
        }

        // Check authorization status
        let authStatus = healthStore.authorizationStatus(for: sleepType)
        Log.debug("Sleep authorization status: \(authStatus.rawValue)", category: .healthkit)

        // Find the sample that matches these times
        let predicate = HKQuery.predicateForSamples(withStart: bedTime, end: wakeTime, options: .strictStartDate)
        Log.debug("Searching for matching HealthKit sleep sample", category: .sleep)

        let query = HKSampleQuery(
            sampleType: sleepType,
            predicate: predicate,
            limit: 1,
            sortDescriptors: nil
        ) { [weak self] _, samples, error in
            if let error = error {
                Log.error("Sleep query error", category: .healthkit, error: error)
                DispatchQueue.main.async {
                    completion(false, error)
                }
                return
            }

            guard let sample = samples?.first as? HKCategorySample else {
                Log.warning("No matching sleep sample found in HealthKit", category: .sleep)
                DispatchQueue.main.async {
                    completion(false, nil)
                }
                return
            }

            Log.debug("Found matching sleep sample, deleting", category: .sleep)
            self?.healthStore.delete(sample) { success, error in
                DispatchQueue.main.async {
                    if success {
                        Log.logSuccess("Sleep data deleted from HealthKit", category: .sleep)
                    } else {
                        Log.logFailure("Sleep data deletion", category: .sleep, error: error)
                    }
                    completion(success, error)
                }
            }
        }

        healthStore.execute(query)
    }

    func fetchSleepData(startDate: Date, completion: @escaping ([SleepEntry]) -> Void) {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            completion([])
            return
        }

        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        let query = HKSampleQuery(
            sampleType: sleepType,
            predicate: predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: [sortDescriptor]
        ) { _, samples, error in
            guard let samples = samples as? [HKCategorySample], error == nil else {
                DispatchQueue.main.async {
                    completion([])
                }
                return
            }

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
                Log.error("Failed to enable sleep background delivery", category: .healthkit, error: error)
            }
        }
    }

    func stopObservingSleep(query: HKObserverQuery) {
        healthStore.stop(query)

        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return }

        healthStore.disableBackgroundDelivery(for: sleepType) { success, error in
            if let error = error {
                Log.error("Failed to disable sleep background delivery", category: .healthkit, error: error)
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
            Log.warning("Attempted to save incomplete fasting session to HealthKit", category: .fasting)
            completion(false, NSError(domain: "HealthKit", code: 5, userInfo: [NSLocalizedDescriptionKey: "Cannot save incomplete fasting session"]))
            return
        }

        guard let endTime = session.endTime else {
            Log.warning("Fasting session missing end time", category: .fasting)
            completion(false, NSError(domain: "HealthKit", code: 5, userInfo: [NSLocalizedDescriptionKey: "Fasting session missing end time"]))
            return
        }

        let duration = session.duration
        let durationHours = duration / 3600
        Log.info("Saving fasting session to HealthKit", category: .fasting, metadata: ["duration": String(format: "%.1fh", durationHours)])

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
                    Log.logFailure("Workout builder begin collection", category: .fasting, error: error)
                    completion(false, error)
                }
                return
            }

            // End the workout collection
            builder.endCollection(withEnd: normalizedEnd) { success, error in
                guard success else {
                    DispatchQueue.main.async {
                        Log.logFailure("Workout builder end collection", category: .fasting, error: error)
                        completion(false, error)
                    }
                    return
                }

                // Add metadata to the builder
                builder.addMetadata(metadata) { success, error in
                    guard success else {
                        DispatchQueue.main.async {
                            Log.logFailure("Workout builder add metadata", category: .fasting, error: error)
                            completion(false, error)
                        }
                        return
                    }

                    // Finish the workout
                    builder.finishWorkout { workout, error in
                        DispatchQueue.main.async {
                            if workout != nil {
                                Log.logSuccess("Fasting session saved to HealthKit", category: .fasting)
                                completion(true, nil)
                            } else {
                                Log.logFailure("Workout builder finish", category: .fasting, error: error)
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
            Log.warning("Cannot delete fasting session without end time", category: .fasting)
            completion(false, nil)
            return
        }

        Log.info("Deleting fasting session from HealthKit", category: .fasting)

        let workoutType = HKObjectType.workoutType()
        let predicate = HKQuery.predicateForSamples(withStart: session.startTime, end: endTime, options: .strictStartDate)

        let query = HKSampleQuery(
            sampleType: workoutType,
            predicate: predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: nil
        ) { [weak self] _, samples, error in
            if let error = error {
                Log.error("Fasting session query error", category: .healthkit, error: error)
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
                Log.warning("No matching fasting workout found in HealthKit", category: .fasting)
                DispatchQueue.main.async {
                    completion(false, nil)
                }
                return
            }

            Log.debug("Found matching fasting workout, deleting", category: .fasting)
            self?.healthStore.delete(fastingWorkout) { success, error in
                DispatchQueue.main.async {
                    if success {
                        Log.logSuccess("Fasting session deleted from HealthKit", category: .fasting)
                    } else {
                        Log.logFailure("Fasting session deletion", category: .fasting, error: error)
                    }
                    completion(success, error)
                }
            }
        }

        healthStore.execute(query)
    }

    /// Fetches all fasting sessions (workouts marked as Fast LIFe) from HealthKit
    func fetchFastingData(startDate: Date, completion: @escaping ([FastingSession]) -> Void) {
        let workoutType = HKObjectType.workoutType()
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        let query = HKSampleQuery(
            sampleType: workoutType,
            predicate: predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: [sortDescriptor]
        ) { _, samples, error in
            guard let workouts = samples as? [HKWorkout], error == nil else {
                DispatchQueue.main.async {
                    completion([])
                }
                return
            }

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

            DispatchQueue.main.async {
                completion(fastingSessions)
            }
        }

        healthStore.execute(query)
    }
}
