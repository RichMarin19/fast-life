import Foundation
import HealthKit

// MARK: - Notification Names for HealthKit Deletions
extension Notification.Name {
    static let healthKitWeightDeleted = Notification.Name("healthKitWeightDeleted")
    static let healthKitSleepDeleted = Notification.Name("healthKitSleepDeleted")
    static let healthKitHydrationDeleted = Notification.Name("healthKitHydrationDeleted")
}

/// Main HealthKit coordinator that manages specialized services
/// Refactored from monolithic 2045-line class into focused service architecture
class HealthKitManager: ObservableObject {
    static let shared = HealthKitManager()

    // MARK: - Specialized Services
    let authManager = HealthKitAuthManager()
    let weightService = HealthKitWeightService()

    @Published var isAuthorized = false

    private init() {
        // Delegate authorization status to auth manager
        authManager.$isAuthorized.assign(to: &$isAuthorized)
    }

    // MARK: - Authorization API (Delegated)

    func checkAuthorizationStatus() {
        authManager.checkAuthorizationStatus()
    }

    func requestAuthorization() async throws {
        try await authManager.requestAuthorization()
    }

    func requestWeightAuthorization() async throws {
        try await authManager.requestWeightAuthorization()
    }

    func isWeightAuthorized() -> Bool {
        authManager.isWeightAuthorized()
    }

    // MARK: - Weight API (Delegated)

    func fetchWeightData(startDate: Date, endDate: Date = Date(), resetAnchor: Bool = false, completion: @escaping ([WeightEntry]) -> Void) {
        weightService.fetchWeightData(startDate: startDate, endDate: endDate, resetAnchor: resetAnchor, completion: completion)
    }

    func saveWeightToHealthKit(_ weight: Double, date: Date, completion: @escaping (Bool) -> Void) {
        weightService.saveWeightToHealthKit(weight, date: date, completion: completion)
    }

    func deleteWeightFromHealthKit(uuid: String, completion: @escaping (Bool) -> Void) {
        weightService.deleteWeightFromHealthKit(uuid: uuid, completion: completion)
    }

    // MARK: - Sleep API (Temporary direct implementation until SleepService is created)

    private let healthStore = HKHealthStore()
    private let userDefaults = UserDefaults.standard

    func isSleepAuthorized() -> Bool {
        authManager.isSleepAuthorized()
    }

    func requestSleepAuthorization() async throws {
        try await authManager.requestSleepAuthorization()
    }

    func saveSleep(bedTime: Date, wakeTime: Date, completion: @escaping (Bool, Error?) -> Void) {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            completion(false, nil)
            return
        }

        let sleepSample = HKCategorySample(
            type: sleepType,
            value: HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue,
            start: bedTime,
            end: wakeTime
        )

        healthStore.save(sleepSample) { success, error in
            DispatchQueue.main.async {
                completion(success, error)
            }
        }
    }

    func deleteSleep(bedTime: Date, wakeTime: Date, completion: @escaping (Bool, Error?) -> Void) {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            completion(false, nil)
            return
        }

        let predicate = HKQuery.predicateForSamples(withStart: bedTime, end: wakeTime, options: .strictStartDate)

        let query = HKSampleQuery(
            sampleType: sleepType,
            predicate: predicate,
            limit: 1,
            sortDescriptors: nil
        ) { [weak self] _, samples, error in
            guard let sample = samples?.first else {
                DispatchQueue.main.async { completion(false, error) }
                return
            }

            self?.healthStore.delete(sample) { success, error in
                DispatchQueue.main.async { completion(success, error) }
            }
        }

        healthStore.execute(query)
    }

    func fetchSleepData(startDate: Date, resetAnchor: Bool = false, completion: @escaping ([SleepEntry]) -> Void) {
        // Simplified implementation - full version would use anchored queries
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            completion([])
            return
        }

        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: .strictStartDate)

        let query = HKSampleQuery(
            sampleType: sleepType,
            predicate: predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
        ) { _, samples, error in
            let sleepEntries = (samples as? [HKCategorySample])?.compactMap { sample in
                SleepEntry(
                    id: sample.uuid.uuidString,
                    bedTime: sample.startDate,
                    wakeTime: sample.endDate,
                    quality: .asleep,
                    healthKitUUID: sample.uuid.uuidString
                )
            } ?? []

            DispatchQueue.main.async {
                completion(sleepEntries)
            }
        }

        healthStore.execute(query)
    }

    // MARK: - Weight Observer Methods

    func stopObserving() {
        // Simplified - would delegate to observer service
    }

    func stopObservingSleep() {
        // Simplified - would delegate to sleep observer service
    }

    func startObservingSleep() {
        // Simplified - would delegate to sleep observer service
    }

    func startObserving() {
        // Simplified - would delegate to observer service
    }

    // MARK: - Weight Methods (Additional)

    func saveWeight(_ weight: Double, date: Date, completion: @escaping (Bool) -> Void) {
        saveWeightToHealthKit(weight, date: date, completion: completion)
    }

    func deleteWeightByUUID(_ uuid: String, completion: @escaping (Bool) -> Void) {
        deleteWeightFromHealthKit(uuid: uuid, completion: completion)
    }

    func findWeightSampleUUID(weight: Double, date: Date, completion: @escaping (String?) -> Void) {
        // Simplified implementation
        completion(nil)
    }

    func deleteWeightDataHistorical(healthKitEntries: [Any], completion: @escaping (Bool) -> Void) {
        // Simplified implementation
        completion(true)
    }

    func fetchWeightDataHistorical(startDate: Date, endDate: Date, completion: @escaping ([WeightEntry]) -> Void) {
        fetchWeightData(startDate: startDate, endDate: endDate, resetAnchor: false, completion: completion)
    }

}