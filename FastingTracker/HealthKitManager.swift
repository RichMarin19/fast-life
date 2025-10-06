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

    func checkAuthorizationStatus() {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("HealthKit is not available on this device")
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
                print("Error fetching weight data: \(String(describing: error))")
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
                    print("Error saving weight data: \(error.localizedDescription)")
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
                print("Error fetching water data: \(String(describing: error))")
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
                    print("Error saving water data: \(error.localizedDescription)")
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
                print("Failed to enable background delivery: \(error.localizedDescription)")
            } else if success {
                print("Background delivery enabled for weight data")
            }
        }
    }

    func stopObserving(query: HKObserverQuery) {
        healthStore.stop(query)

        // Disable background delivery when no longer observing
        guard let weightType = HKObjectType.quantityType(forIdentifier: .bodyMass) else { return }

        healthStore.disableBackgroundDelivery(for: weightType) { success, error in
            if let error = error {
                print("Failed to disable background delivery: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Sleep Tracking Methods

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

    func saveSleep(bedTime: Date, wakeTime: Date, completion: @escaping (Bool, Error?) -> Void) {
        print("\n💾 === HEALTHKIT SAVE SLEEP ===")
        print("Bed Time: \(bedTime)")
        print("Wake Time: \(wakeTime)")
        print("Duration: \(String(format: "%.1f", (wakeTime.timeIntervalSince(bedTime)) / 3600))h")

        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            print("❌ Failed to get sleep type")
            completion(false, nil)
            return
        }

        // Check authorization status
        let authStatus = healthStore.authorizationStatus(for: sleepType)
        print("Authorization Status: \(authStatus.rawValue)")
        switch authStatus {
        case .notDetermined:
            print("⚠️  Authorization not determined - user hasn't granted permission yet")
        case .sharingDenied:
            print("❌ Authorization denied - user declined HealthKit access")
        case .sharingAuthorized:
            print("✅ Authorization granted")
        @unknown default:
            print("⚠️  Unknown authorization status")
        }

        let sleepSample = HKCategorySample(
            type: sleepType,
            value: HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue,
            start: bedTime,
            end: wakeTime
        )

        print("🔄 Attempting to save to HealthKit...")
        healthStore.save(sleepSample) { success, error in
            DispatchQueue.main.async {
                if success {
                    print("✅ HealthKit save successful")
                } else {
                    print("❌ HealthKit save failed: \(String(describing: error))")
                }
                print("============================\n")
                completion(success, error)
            }
        }
    }

    func deleteSleep(bedTime: Date, wakeTime: Date, completion: @escaping (Bool, Error?) -> Void) {
        print("\n🗑️  === HEALTHKIT DELETE SLEEP ===")
        print("Bed Time: \(bedTime)")
        print("Wake Time: \(wakeTime)")

        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            print("❌ Failed to get sleep type")
            completion(false, nil)
            return
        }

        // Check authorization status
        let authStatus = healthStore.authorizationStatus(for: sleepType)
        print("Authorization Status: \(authStatus.rawValue)")

        // Find the sample that matches these times
        let predicate = HKQuery.predicateForSamples(withStart: bedTime, end: wakeTime, options: .strictStartDate)
        print("🔍 Searching for matching HealthKit sample...")

        let query = HKSampleQuery(
            sampleType: sleepType,
            predicate: predicate,
            limit: 1,
            sortDescriptors: nil
        ) { [weak self] _, samples, error in
            if let error = error {
                print("❌ Query error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(false, error)
                }
                return
            }

            guard let sample = samples?.first as? HKCategorySample else {
                print("⚠️  No matching sample found in HealthKit (may not exist)")
                DispatchQueue.main.async {
                    completion(false, nil)
                }
                return
            }

            print("✅ Found matching sample, deleting...")
            self?.healthStore.delete(sample) { success, error in
                DispatchQueue.main.async {
                    if success {
                        print("✅ HealthKit delete successful")
                    } else {
                        print("❌ HealthKit delete failed: \(String(describing: error))")
                    }
                    print("==============================\n")
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
                print("Failed to enable background delivery: \(error.localizedDescription)")
            }
        }
    }

    func stopObservingSleep(query: HKObserverQuery) {
        healthStore.stop(query)

        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return }

        healthStore.disableBackgroundDelivery(for: sleepType) { success, error in
            if let error = error {
                print("Failed to disable background delivery: \(error.localizedDescription)")
            }
        }
    }
}
