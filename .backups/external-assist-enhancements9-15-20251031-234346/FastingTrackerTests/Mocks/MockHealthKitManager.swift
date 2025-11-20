//
// MockHealthKitManager.swift
// FastLIFe
//
// Created for Task 1A: Thread Safety Testing
// Mock implementation of HealthKitManagerProtocol for unit tests
//

import Foundation
import HealthKit
@testable import FastLIFe

/// Mock HealthKit manager for testing without actual HealthKit access
/// **Industry Pattern:** Protocol-based mocking for external dependencies
/// **Reference:** Apple WWDC 2017 "Testing in Xcode"
class MockHealthKitManager: HealthKitManagerProtocol {

    // MARK: - Test Control Properties

    var isAuthorized: Bool = true
    var isWeightAuthorizedValue: Bool = true
    var isFastingAuthorizedValue: Bool = true
    var isHydrationAuthorizedValue: Bool = true
    var isSleepAuthorizedValue: Bool = true
    var isMindfulnessAuthorizedValue: Bool = true
    var isHeartRateAuthorizedValue: Bool = true

    var lastWeightSyncDate: Date?
    var lastWeightSyncError: String?
    var sharingDenied: Bool = false

    // Tracking for test assertions
    var saveWeightCalled = false
    var fetchWeightDataCalled = false
    var deleteWeightCalled = false
    var requestAuthorizationCalled = false

    var savedWeights: [(weight: Double, bmi: Double?, bodyFat: Double?, date: Date)] = []
    var mockWeightEntries: [WeightEntry] = []

    // Configurable callback for saveWeight (for observer suppression testing)
    var onSaveWeight: ((Double, Double?, Double?, Date, @escaping (Bool, Error?) -> Void) -> Void)?

    // MARK: - Authorization API

    func checkAuthorizationStatus() {
        // No-op for testing
    }

    func requestAuthorization() async throws {
        requestAuthorizationCalled = true
    }

    func requestAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        requestAuthorizationCalled = true
        completion(true, nil)
    }

    func requestWeightAuthorization() async throws {
        requestAuthorizationCalled = true
    }

    func requestWeightAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        requestAuthorizationCalled = true
        completion(isWeightAuthorizedValue, nil)
    }

    func requestHydrationAuthorization() async throws {
        requestAuthorizationCalled = true
    }

    func requestHydrationAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        requestAuthorizationCalled = true
        completion(isHydrationAuthorizedValue, nil)
    }

    func requestFastingAuthorization() async throws {
        requestAuthorizationCalled = true
    }

    func requestFastingAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        requestAuthorizationCalled = true
        completion(isFastingAuthorizedValue, nil)
    }

    func requestHeartRateAuthorization() async throws {
        requestAuthorizationCalled = true
    }

    func requestSleepAuthorization() async throws {
        requestAuthorizationCalled = true
    }

    func requestSleepAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        requestAuthorizationCalled = true
        completion(isSleepAuthorizedValue, nil)
    }

    func requestMindfulnessAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        requestAuthorizationCalled = true
        completion(isMindfulnessAuthorizedValue, nil)
    }

    // MARK: - Authorization Status Checks

    func isHeartRateAuthorized() -> Bool { isHeartRateAuthorizedValue }
    func isHydrationAuthorized() -> Bool { isHydrationAuthorizedValue }
    func isWaterAuthorized() -> Bool { isHydrationAuthorizedValue }
    func isFastingAuthorized() -> Bool { isFastingAuthorizedValue }
    func isWeightAuthorized() -> Bool { isWeightAuthorizedValue }
    func isSleepAuthorized() -> Bool { isSleepAuthorizedValue }
    func isMindfulnessAuthorized() -> Bool { isMindfulnessAuthorizedValue }

    func getWeightAuthorizationStatus() -> HKAuthorizationStatus {
        isWeightAuthorizedValue ? .sharingAuthorized : .sharingDenied
    }

    func getFastingAuthorizationStatus() -> HKAuthorizationStatus {
        isFastingAuthorizedValue ? .sharingAuthorized : .sharingDenied
    }

    func getHealthStore() -> HKHealthStore {
        return HKHealthStore()
    }

    // MARK: - Weight API

    func fetchWeightData(startDate: Date, endDate: Date, resetAnchor: Bool, completion: @escaping ([WeightEntry]) -> Void) {
        fetchWeightDataCalled = true
        // Return mock data on background thread to simulate async behavior
        DispatchQueue.global(qos: .background).async {
            completion(self.mockWeightEntries)
        }
    }

    func fetchWeightDataHistorical(startDate: Date, completion: @escaping ([WeightEntry]) -> Void) {
        fetchWeightDataCalled = true
        DispatchQueue.global(qos: .background).async {
            completion(self.mockWeightEntries)
        }
    }

    func fetchWeightDataHistorical(startDate: Date, endDate: Date, completion: @escaping ([WeightEntry]) -> Void) {
        fetchWeightDataCalled = true
        DispatchQueue.global(qos: .background).async {
            completion(self.mockWeightEntries)
        }
    }

    func saveWeightToHealthKit(_ weight: Double, date: Date, completion: @escaping (Bool) -> Void) {
        saveWeightCalled = true
        savedWeights.append((weight, nil, nil, date))
        DispatchQueue.global(qos: .background).async {
            completion(true)
        }
    }

    func saveWeight(weight: Double, bmi: Double?, bodyFat: Double?, date: Date, completion: @escaping (Bool, Error?) -> Void) {
        saveWeightCalled = true
        savedWeights.append((weight, bmi, bodyFat, date))

        // Call custom callback if configured (for observer suppression testing)
        if let callback = onSaveWeight {
            callback(weight, bmi, bodyFat, date, completion)
        } else {
            // Default behavior: async success
            DispatchQueue.global(qos: .background).async {
                completion(true, nil)
            }
        }
    }

    func deleteWeightFromHealthKit(uuid: String, completion: @escaping (Bool) -> Void) {
        deleteWeightCalled = true
        DispatchQueue.global(qos: .background).async {
            completion(true)
        }
    }

    func deleteWeightByUUID(_ uuid: String, completion: @escaping (Bool, Error?) -> Void) {
        deleteWeightCalled = true
        DispatchQueue.global(qos: .background).async {
            completion(true, nil)
        }
    }

    func deleteWeightByUUID(_ uuid: UUID, completion: @escaping (Bool, Error?) -> Void) {
        deleteWeightCalled = true
        DispatchQueue.global(qos: .background).async {
            completion(true, nil)
        }
    }

    func findWeightSampleUUID(date: Date, weight: Double, completion: @escaping (String?) -> Void) {
        DispatchQueue.global(qos: .background).async {
            completion(UUID().uuidString)
        }
    }

    func deleteWeightDataHistorical(healthKitEntries: [Any], completion: @escaping (Bool) -> Void) {
        deleteWeightCalled = true
        DispatchQueue.global(qos: .background).async {
            completion(true)
        }
    }

    // MARK: - Fasting API

    func fetchFastingSessions(startDate: Date, completion: @escaping ([FastingSession]) -> Void) {
        DispatchQueue.global(qos: .background).async {
            completion([])
        }
    }

    func saveFastingSession(_ session: FastingSession, completion: @escaping (Bool, Error?) -> Void) {
        DispatchQueue.global(qos: .background).async {
            completion(true, nil)
        }
    }

    func startObservingFasting() {}
    func startObservingFasting(callback: @escaping () -> Void) {}
    func stopObservingFasting() {}
    func updateFastingSyncStatus(success: Bool) {}

    // MARK: - Hydration API

    func fetchWaterData(startDate: Date, completion: @escaping ([(Date, Double)]) -> Void) {
        DispatchQueue.global(qos: .background).async {
            completion([])
        }
    }

    func saveWater(amount: Double, date: Date, completion: @escaping (Bool, Error?) -> Void) {
        DispatchQueue.global(qos: .background).async {
            completion(true, nil)
        }
    }

    func startObservingHydration() {}
    func startObservingHydration(callback: @escaping () -> Void) {}
    func stopObservingHydration() {}
    func stopObservingHydration(query: HKObserverQuery) {}

    // MARK: - Sleep API

    func fetchSleepData(startDate: Date, resetAnchor: Bool, completion: @escaping ([SleepEntry]) -> Void) {
        DispatchQueue.global(qos: .background).async {
            completion([])
        }
    }

    func saveSleep(bedTime: Date, wakeTime: Date, completion: @escaping (Bool, Error?) -> Void) {
        DispatchQueue.global(qos: .background).async {
            completion(true, nil)
        }
    }

    func deleteSleep(bedTime: Date, wakeTime: Date, completion: @escaping (Bool, Error?) -> Void) {
        DispatchQueue.global(qos: .background).async {
            completion(true, nil)
        }
    }

    // MARK: - Mood/Mindfulness API

    func saveMoodAsMindfulness(moodLevel: Int, energyLevel: Int, notes: String?, date: Date, completion: @escaping (Bool, Error?) -> Void) {
        DispatchQueue.global(qos: .background).async {
            completion(true, nil)
        }
    }

    func fetchMoodFromMindfulness(startDate: Date, completion: @escaping ([MoodEntry]) -> Void) {
        DispatchQueue.global(qos: .background).async {
            completion([])
        }
    }

    func startObservingMindfulness(completion: (() -> Void)?) {}
    func stopObservingMindfulness() {}

    // MARK: - Observer Management

    func startObserving() {}
    func startObserving(query: HKObserverQuery) {}
    func stopObserving() {}
    func stopObserving(query: HKObserverQuery) {}
    func startObservingSleep() {}
    func startObservingSleep(query: HKObserverQuery) {}
    func stopObservingSleep() {}
    func stopObservingSleep(query: HKObserverQuery) {}

    // MARK: - Test Helper Methods

    func reset() {
        isAuthorized = true
        isWeightAuthorizedValue = true
        saveWeightCalled = false
        fetchWeightDataCalled = false
        deleteWeightCalled = false
        requestAuthorizationCalled = false
        savedWeights.removeAll()
        mockWeightEntries.removeAll()
        onSaveWeight = nil
    }

    func setMockWeightEntries(_ entries: [WeightEntry]) {
        mockWeightEntries = entries
    }
}
