import Foundation
import HealthKit

/// Specialized service for HealthKit weight data operations
/// Following Apple HealthKit Best Practices for efficient data sync
/// CRITICAL FIX: Uses dependency injection for shared HKHealthStore to prevent authorization conflicts
class HealthKitWeightService {
    private let healthStore: HKHealthStore
    private let userDefaults = UserDefaults.standard

    /// Industry standard: Dependency injection constructor for shared store
    /// Prevents multiple HKHealthStore instances that cause SHARING DENIED issues
    init(healthStore: HKHealthStore) {
        self.healthStore = healthStore
    }

    private enum AnchorKeys {
        static let weight = "HealthKitAnchor_Weight"
    }

    private enum SyncTimestampKeys {
        static let weight = "HealthKitSyncTimestamp_Weight"
    }

    private enum SyncErrorKeys {
        static let weight = "HealthKitSyncError_Weight"
    }

    // MARK: - Read Weight Data

    /// Fetches weight data using HKAnchoredObjectQuery for efficient incremental sync
    /// Following Apple HealthKit Best Practices to prevent duplicates and improve performance
    func fetchWeightData(startDate: Date, endDate: Date = Date(), resetAnchor: Bool = false, completion: @escaping ([WeightEntry]) -> Void) {
        fetchWeightDataAnchored(startDate: startDate, endDate: endDate, resetAnchor: resetAnchor, completion: completion)
    }

    private func fetchWeightDataAnchored(startDate: Date, endDate: Date = Date(), resetAnchor: Bool = false, completion: @escaping ([WeightEntry]) -> Void) {
        guard let weightType = HKObjectType.quantityType(forIdentifier: .bodyMass) else {
            DispatchQueue.main.async { completion([]) }
            return
        }

        let savedAnchor = resetAnchor ? nil : loadAnchor(forKey: AnchorKeys.weight)

        if resetAnchor {
            AppLogger.info("Resetting HealthKit anchor for fresh deletion detection", category: AppLogger.healthKit)
        }

        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)

        let query = HKAnchoredObjectQuery(
            type: weightType,
            predicate: predicate,
            anchor: savedAnchor,
            limit: HKObjectQueryNoLimit
        ) { [weak self] query, addedObjects, deletedObjects, newAnchor, error in

            if let error = error {
                let errorMessage = self?.handleHealthKitError(error, operation: "fetch weight data (anchored)") ?? "Unknown error"
                AppLogger.error("Enhanced error handling for anchored weight fetch: \(errorMessage)", category: AppLogger.healthKit, error: error)

                self?.saveSyncError(for: SyncErrorKeys.weight, error: errorMessage)

                CrashReportManager.shared.recordHealthKitError(error, context: [
                    "operation": "fetchWeightData_anchored",
                    "startDate": startDate.description,
                    "anchor": savedAnchor?.description ?? "nil",
                    "userFriendlyError": errorMessage
                ])

                DispatchQueue.main.async { completion([]) }
                return
            }

            self?.saveAnchor(newAnchor, forKey: AnchorKeys.weight)
            self?.saveSyncTimestamp(for: SyncTimestampKeys.weight)
            self?.saveSyncError(for: SyncErrorKeys.weight, error: nil)

            if let deletedSamples = deletedObjects as? [HKQuantitySample], !deletedSamples.isEmpty {
                AppLogger.info("Processing \(deletedSamples.count) deleted weight samples from HealthKit", category: AppLogger.healthKit)
                self?.processDeletedWeightSamples(deletedSamples)
            }

            guard let samples = addedObjects as? [HKQuantitySample] else {
                DispatchQueue.main.async { completion([]) }
                return
            }

            AppLogger.info("Fetched \(samples.count) weight samples from HealthKit", category: AppLogger.healthKit)
            self?.processWeightSamples(samples, completion: completion)
        }

        healthStore.execute(query)
    }

    // MARK: - Write Weight Data

    func saveWeightToHealthKit(_ weight: Double, date: Date, completion: @escaping (Bool) -> Void) {
        guard let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass) else {
            completion(false)
            return
        }

        let weightQuantity = HKQuantity(unit: HKUnit.pound(), doubleValue: weight)
        let weightSample = HKQuantitySample(
            type: weightType,
            quantity: weightQuantity,
            start: date,
            end: date
        )

        healthStore.save(weightSample) { [weak self] success, error in
            if let error = error {
                AppLogger.error("Failed to save weight to HealthKit", category: AppLogger.healthKit, error: error)
                completion(false)
            } else {
                AppLogger.info("Successfully saved weight \(weight) lbs to HealthKit", category: AppLogger.healthKit)
                self?.saveSyncTimestamp(for: SyncTimestampKeys.weight)
                completion(true)
            }
        }
    }

    // MARK: - Delete Weight Data

    func deleteWeightFromHealthKit(uuid: String, completion: @escaping (Bool) -> Void) {
        guard let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass),
              let uuidObj = UUID(uuidString: uuid) else {
            completion(false)
            return
        }

        let predicate = HKQuery.predicateForObject(with: uuidObj)

        let query = HKSampleQuery(
            sampleType: weightType,
            predicate: predicate,
            limit: 1,
            sortDescriptors: nil
        ) { [weak self] _, samples, error in

            guard let sample = samples?.first else {
                DispatchQueue.main.async { completion(false) }
                return
            }

            self?.healthStore.delete(sample) { success, error in
                if let error = error {
                    AppLogger.error("Failed to delete weight from HealthKit", category: AppLogger.healthKit, error: error)
                    DispatchQueue.main.async { completion(false) }
                } else {
                    AppLogger.info("Successfully deleted weight from HealthKit", category: AppLogger.healthKit)
                    self?.saveSyncTimestamp(for: SyncTimestampKeys.weight)
                    DispatchQueue.main.async { completion(true) }
                }
            }
        }

        healthStore.execute(query)
    }

    // MARK: - Private Helper Methods

    private func processWeightSamples(_ samples: [HKQuantitySample], completion: @escaping ([WeightEntry]) -> Void) {
        let calendar = Calendar.current

        // Group samples by day and get most recent entry per day
        var weightsByDay: [String: (sample: HKQuantitySample, entry: WeightEntry)] = [:]

        for sample in samples {
            let dayKey = calendar.dateInterval(of: .day, for: sample.startDate)?.start.description ?? sample.startDate.description
            let weight = sample.quantity.doubleValue(for: HKUnit.pound())
            let source = detectWeightSource(from: sample)

            let entry = WeightEntry(
                id: sample.uuid,
                date: sample.startDate,
                weight: weight,
                source: source,
                healthKitUUID: sample.uuid
            )

            // Keep the most recent sample for each day
            if let existing = weightsByDay[dayKey] {
                if sample.startDate > existing.sample.startDate {
                    weightsByDay[dayKey] = (sample: sample, entry: entry)
                }
            } else {
                weightsByDay[dayKey] = (sample: sample, entry: entry)
            }
        }

        let entries = Array(weightsByDay.values.map { $0.entry }).sorted { $0.date > $1.date }

        DispatchQueue.main.async {
            completion(entries)
        }
    }

    private func processDeletedWeightSamples(_ deletedSamples: [HKQuantitySample]) {
        for sample in deletedSamples {
            NotificationCenter.default.post(
                name: .healthKitWeightDeleted,
                object: nil,
                userInfo: ["uuid": sample.uuid.uuidString]
            )
        }
    }

    private func detectWeightSource(from sample: HKQuantitySample) -> WeightSource {
        let sourceName = sample.sourceRevision.source.name.lowercased()

        if sourceName.contains("scale") || sourceName.contains("withings") {
            return .smartScale
        } else if sourceName.contains("health") && sourceName.contains("iphone") {
            return .manualEntry
        } else {
            return .other
        }
    }

    private func handleHealthKitError(_ error: Error, operation: String) -> String {
        if let hkError = error as? HKError {
            return hkError.localizedDescription
        }
        return error.localizedDescription
    }

    // MARK: - Anchor Management

    private func saveAnchor(_ anchor: HKQueryAnchor?, forKey key: String) {
        guard let anchor = anchor else { return }
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: anchor, requiringSecureCoding: true)
            userDefaults.set(data, forKey: key)
        } catch {
            AppLogger.error("Failed to save anchor for key \(key)", category: AppLogger.healthKit, error: error)
        }
    }

    private func loadAnchor(forKey key: String) -> HKQueryAnchor? {
        guard let data = userDefaults.data(forKey: key) else { return nil }
        do {
            return try NSKeyedUnarchiver.unarchivedObject(ofClass: HKQueryAnchor.self, from: data)
        } catch {
            AppLogger.error("Failed to load anchor for key \(key)", category: AppLogger.healthKit, error: error)
            return nil
        }
    }

    private func saveSyncTimestamp(for key: String) {
        userDefaults.set(Date(), forKey: key)
    }

    private func saveSyncError(for key: String, error: String?) {
        if let error = error {
            userDefaults.set(error, forKey: key)
        } else {
            userDefaults.removeObject(forKey: key)
        }
    }
}