import Foundation
import HealthKit

/// Manages HealthKit authorization requests and status checking
/// Following Apple HealthKit Programming Guide for proper authorization patterns
/// CRITICAL FIX: Uses dependency injection for shared HKHealthStore to prevent authorization conflicts
class HealthKitAuthManager: ObservableObject {
    private let healthStore: HKHealthStore
    @Published var isAuthorized = false

    /// Industry standard: Dependency injection constructor for shared store
    /// Prevents multiple HKHealthStore instances that cause SHARING DENIED issues
    init(healthStore: HKHealthStore) {
        self.healthStore = healthStore
    }

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

    func isHydrationAuthorized() -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else {
            return false
        }

        guard let waterType = HKObjectType.quantityType(forIdentifier: .dietaryWater) else {
            return false
        }

        let status = healthStore.authorizationStatus(for: waterType)
        return status == .sharingAuthorized
    }

    func isHeartRateAuthorized() -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else {
            return false
        }

        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else {
            return false
        }

        let status = healthStore.authorizationStatus(for: heartRateType)
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

    /// Check if mindfulness data is authorized for read/write
    /// Following Apple HealthKit Programming Guide for mindful session category
    func isMindfulnessAuthorized() -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else {
            return false
        }

        guard let mindfulType = HKObjectType.categoryType(forIdentifier: .mindfulSession) else {
            return false
        }

        let status = healthStore.authorizationStatus(for: mindfulType)
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

    func requestWeightAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.notAvailable
        }

        guard let weightType = HKObjectType.quantityType(forIdentifier: .bodyMass) else {
            throw HealthKitError.invalidType
        }

        let typesToRead: Set<HKObjectType> = [weightType]
        let typesToWrite: Set<HKSampleType> = [weightType]

        try await healthStore.requestAuthorization(toShare: typesToWrite, read: typesToRead)

        await MainActor.run {
            checkAuthorizationStatus()
        }
    }

    func requestHydrationAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.notAvailable
        }

        guard let waterType = HKObjectType.quantityType(forIdentifier: .dietaryWater) else {
            throw HealthKitError.invalidType
        }

        let typesToRead: Set<HKObjectType> = [waterType]
        let typesToWrite: Set<HKSampleType> = [waterType]

        try await healthStore.requestAuthorization(toShare: typesToWrite, read: typesToRead)

        await MainActor.run {
            checkAuthorizationStatus()
        }
    }

    func requestHeartRateAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.notAvailable
        }

        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else {
            throw HealthKitError.invalidType
        }

        let typesToRead: Set<HKObjectType> = [heartRateType]
        let typesToWrite: Set<HKSampleType> = [] // Heart rate is read-only

        try await healthStore.requestAuthorization(toShare: typesToWrite, read: typesToRead)

        await MainActor.run {
            checkAuthorizationStatus()
        }
    }

    func requestSleepAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.notAvailable
        }

        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            throw HealthKitError.invalidType
        }

        let typesToRead: Set<HKObjectType> = [sleepType]
        let typesToWrite: Set<HKSampleType> = [sleepType]

        try await healthStore.requestAuthorization(toShare: typesToWrite, read: typesToRead)

        await MainActor.run {
            checkAuthorizationStatus()
        }
    }

    func requestFastingAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.notAvailable
        }

        let workoutType = HKObjectType.workoutType()
        let typesToRead: Set<HKObjectType> = [workoutType]
        let typesToWrite: Set<HKSampleType> = [workoutType]

        try await healthStore.requestAuthorization(toShare: typesToWrite, read: typesToRead)

        await MainActor.run {
            checkAuthorizationStatus()
        }
    }

    func requestMindfulnessAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.notAvailable
        }

        guard let mindfulType = HKObjectType.categoryType(forIdentifier: .mindfulSession) else {
            throw HealthKitError.invalidType
        }

        let typesToRead: Set<HKObjectType> = [mindfulType]
        let typesToWrite: Set<HKSampleType> = [mindfulType]

        try await healthStore.requestAuthorization(toShare: typesToWrite, read: typesToRead)

        await MainActor.run {
            checkAuthorizationStatus()
        }
    }

    // MARK: - Legacy Authorization (For "Sync All" Features Only)

    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.notAvailable
        }

        let allTypes = Set([
            HKObjectType.quantityType(forIdentifier: .bodyMass)!,
            HKObjectType.quantityType(forIdentifier: .dietaryWater)!,
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
            HKObjectType.workoutType(),
            HKObjectType.categoryType(forIdentifier: .mindfulSession)!
        ])

        try await healthStore.requestAuthorization(toShare: allTypes, read: allTypes)

        await MainActor.run {
            checkAuthorizationStatus()
        }
    }
}

// MARK: - HealthKit Error Types

enum HealthKitError: Error, LocalizedError {
    case notAvailable
    case notAuthorized
    case invalidType
    case syncFailed(String)
    case dataNotFound

    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "HealthKit is not available on this device"
        case .notAuthorized:
            return "HealthKit access not authorized"
        case .invalidType:
            return "Invalid HealthKit data type"
        case .syncFailed(let message):
            return "HealthKit sync failed: \(message)"
        case .dataNotFound:
            return "No HealthKit data found"
        }
    }
}