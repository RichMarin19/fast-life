import Foundation
import HealthKit

/// Protocol abstraction for HealthKit operations
/// Enables dependency injection and mocking for tests
/// Following Apple's HealthKit programming guide patterns
/// Phase 1 of MVVM Strategy: Protocol abstractions (testability foundation)
protocol HealthKitManagerProtocol: AnyObject {

    // MARK: - Published State
    var isAuthorized: Bool { get }

    // MARK: - Authorization API
    func checkAuthorizationStatus()
    func requestAuthorization() async throws
    func requestAuthorization(completion: @escaping (Bool, Error?) -> Void)
    func requestWeightAuthorization() async throws
    func requestWeightAuthorization(completion: @escaping (Bool, Error?) -> Void)
    func requestHydrationAuthorization() async throws
    func requestHydrationAuthorization(completion: @escaping (Bool, Error?) -> Void)
    func requestFastingAuthorization() async throws
    func requestFastingAuthorization(completion: @escaping (Bool, Error?) -> Void)
    func requestHeartRateAuthorization() async throws
    func requestSleepAuthorization() async throws
    func requestSleepAuthorization(completion: @escaping (Bool, Error?) -> Void)
    func requestMindfulnessAuthorization(completion: @escaping (Bool, Error?) -> Void)

    // MARK: - Authorization Status Checks
    func isHeartRateAuthorized() -> Bool
    func isHydrationAuthorized() -> Bool
    func isWaterAuthorized() -> Bool // Alias for isHydrationAuthorized
    func isFastingAuthorized() -> Bool
    func isWeightAuthorized() -> Bool
    func isSleepAuthorized() -> Bool
    func isMindfulnessAuthorized() -> Bool
    func getWeightAuthorizationStatus() -> HKAuthorizationStatus
    func getFastingAuthorizationStatus() -> HKAuthorizationStatus
    func getHealthStore() -> HKHealthStore

    // MARK: - Weight API
    func fetchWeightData(startDate: Date, endDate: Date, resetAnchor: Bool, completion: @escaping ([WeightEntry]) -> Void)
    func fetchWeightDataHistorical(startDate: Date, completion: @escaping ([WeightEntry]) -> Void)
    func fetchWeightDataHistorical(startDate: Date, endDate: Date, completion: @escaping ([WeightEntry]) -> Void)
    func saveWeightToHealthKit(_ weight: Double, date: Date, completion: @escaping (Bool) -> Void)
    func saveWeight(weight: Double, bmi: Double?, bodyFat: Double?, date: Date, completion: @escaping (Bool, Error?) -> Void)
    func deleteWeightFromHealthKit(uuid: String, completion: @escaping (Bool) -> Void)
    func deleteWeightByUUID(_ uuid: String, completion: @escaping (Bool, Error?) -> Void)
    func deleteWeightByUUID(_ uuid: UUID, completion: @escaping (Bool, Error?) -> Void)
    func findWeightSampleUUID(date: Date, weight: Double, completion: @escaping (String?) -> Void)
    func deleteWeightDataHistorical(healthKitEntries: [Any], completion: @escaping (Bool) -> Void)

    // MARK: - Weight Sync Properties
    var lastWeightSyncDate: Date? { get }
    var lastWeightSyncError: String? { get }
    var sharingDenied: Bool { get }

    // MARK: - Fasting API
    func fetchFastingSessions(startDate: Date, completion: @escaping ([FastingSession]) -> Void)
    func saveFastingSession(_ session: FastingSession, completion: @escaping (Bool, Error?) -> Void)
    func startObservingFasting()
    func startObservingFasting(callback: @escaping () -> Void)
    func stopObservingFasting()
    func updateFastingSyncStatus(success: Bool)

    // MARK: - Hydration API
    func fetchWaterData(startDate: Date, completion: @escaping ([(Date, Double)]) -> Void)
    func saveWater(amount: Double, date: Date, completion: @escaping (Bool, Error?) -> Void)
    func startObservingHydration()
    func startObservingHydration(callback: @escaping () -> Void)
    func stopObservingHydration()
    func stopObservingHydration(query: HKObserverQuery)

    // MARK: - Sleep API
    func fetchSleepData(startDate: Date, resetAnchor: Bool, completion: @escaping ([SleepEntry]) -> Void)
    func saveSleep(bedTime: Date, wakeTime: Date, completion: @escaping (Bool, Error?) -> Void)
    func deleteSleep(bedTime: Date, wakeTime: Date, completion: @escaping (Bool, Error?) -> Void)

    // MARK: - Mood/Mindfulness API
    func saveMoodAsMindfulness(moodLevel: Int, energyLevel: Int, notes: String?, date: Date, completion: @escaping (Bool, Error?) -> Void)
    func fetchMoodFromMindfulness(startDate: Date, completion: @escaping ([MoodEntry]) -> Void)
    func startObservingMindfulness(completion: (() -> Void)?)
    func stopObservingMindfulness()

    // MARK: - Observer Management
    func startObserving()
    func startObserving(query: HKObserverQuery)
    func stopObserving()
    func stopObserving(query: HKObserverQuery)
    func startObservingSleep()
    func startObservingSleep(query: HKObserverQuery)
    func stopObservingSleep()
    func stopObservingSleep(query: HKObserverQuery)
}

// MARK: - Protocol Conformance
// Existing HealthKitManager adopts protocol without code changes
extension HealthKitManager: HealthKitManagerProtocol { }
