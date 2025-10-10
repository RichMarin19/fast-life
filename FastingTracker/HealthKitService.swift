import Foundation
import HealthKit

// MARK: - Shared HealthKit Service Layer
// Eliminates code duplication across manager classes while preserving granular control
// Following Apple HealthKit Programming Guide patterns and Swift API Design Guidelines

/// Shared utility service for common HealthKit operations
/// Centralizes authorization patterns while preserving individual tracker settings
class HealthKitService {

    // MARK: - Data Type Definitions

    /// Supported HealthKit data types for Fast LIFe app
    enum DataType {
        case weight
        case hydration
        case sleep
        case fasting
        case mindfulness
        case comprehensive // All data types for advanced sync

        /// Get read types for this data type
        var readTypes: Set<HKObjectType> {
            switch self {
            case .weight:
                return [
                    HKObjectType.quantityType(forIdentifier: .bodyMass)!,
                    HKObjectType.quantityType(forIdentifier: .bodyMassIndex)!,
                    HKObjectType.quantityType(forIdentifier: .bodyFatPercentage)!
                ]
            case .hydration:
                return [
                    HKObjectType.quantityType(forIdentifier: .dietaryWater)!
                ]
            case .sleep:
                return [
                    HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
                ]
            case .fasting:
                return [
                    HKObjectType.workoutType() // Fasting sessions stored as workouts
                ]
            case .mindfulness:
                return [
                    HKObjectType.categoryType(forIdentifier: .mindfulSession)!
                ]
            case .comprehensive:
                // Combine all data types for advanced sync
                var allTypes = Set<HKObjectType>()
                allTypes.formUnion(DataType.weight.readTypes)
                allTypes.formUnion(DataType.hydration.readTypes)
                allTypes.formUnion(DataType.sleep.readTypes)
                allTypes.formUnion(DataType.fasting.readTypes)
                allTypes.formUnion(DataType.mindfulness.readTypes)
                return allTypes
            }
        }

        /// Get write types for this data type
        var writeTypes: Set<HKSampleType> {
            switch self {
            case .weight:
                return [
                    HKObjectType.quantityType(forIdentifier: .bodyMass)! as HKSampleType,
                    HKObjectType.quantityType(forIdentifier: .bodyMassIndex)! as HKSampleType,
                    HKObjectType.quantityType(forIdentifier: .bodyFatPercentage)! as HKSampleType
                ]
            case .hydration:
                return [
                    HKObjectType.quantityType(forIdentifier: .dietaryWater)! as HKSampleType
                ]
            case .sleep:
                return [
                    HKObjectType.categoryType(forIdentifier: .sleepAnalysis)! as HKSampleType
                ]
            case .fasting:
                return [
                    HKObjectType.workoutType() as HKSampleType // Fasting sessions stored as workouts
                ]
            case .mindfulness:
                return [
                    HKObjectType.categoryType(forIdentifier: .mindfulSession)! as HKSampleType
                ]
            case .comprehensive:
                // Combine all data types for advanced sync
                var allTypes = Set<HKSampleType>()
                allTypes.formUnion(DataType.weight.writeTypes)
                allTypes.formUnion(DataType.hydration.writeTypes)
                allTypes.formUnion(DataType.sleep.writeTypes)
                allTypes.formUnion(DataType.fasting.writeTypes)
                allTypes.formUnion(DataType.mindfulness.writeTypes)
                return allTypes
            }
        }

        /// Human-readable name for logging
        var displayName: String {
            switch self {
            case .weight: return "Weight"
            case .hydration: return "Hydration"
            case .sleep: return "Sleep"
            case .fasting: return "Fasting"
            case .mindfulness: return "Mindfulness"
            case .comprehensive: return "Comprehensive"
            }
        }
    }

    // MARK: - Shared Authorization Pattern

    /// Standardized HealthKit authorization request following Apple patterns
    /// - Parameters:
    ///   - dataType: The specific data type to request authorization for
    ///   - completion: Callback with success status and optional error
    static func requestAuthorization(
        for dataType: DataType,
        completion: @escaping (Bool, Error?) -> Void
    ) {
        AppLogger.info("Requesting authorization for \(dataType.displayName)", category: AppLogger.healthKit)

        // Standard Apple pattern: Check if HealthKit is available first
        guard HKHealthStore.isHealthDataAvailable() else {
            let error = NSError(
                domain: "HealthKit",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "HealthKit is not available on this device"]
            )
            AppLogger.warning("HealthKit not available on this device", category: AppLogger.healthKit)
            completion(false, error)
            return
        }

        let readTypes = dataType.readTypes
        let writeTypes = dataType.writeTypes

        // Debug logging for transparency
        AppLogger.info("DEBUG: readTypes count: \(readTypes.count), writeTypes count: \(writeTypes.count)", category: AppLogger.healthKit)
        AppLogger.info("Requesting authorization for \(dataType.displayName) tracking", category: AppLogger.healthKit)

        // Use shared HealthKitManager instance to maintain singleton pattern
        let healthStore = HealthKitManager.shared.getHealthStore()

        healthStore.requestAuthorization(toShare: writeTypes, read: readTypes) { success, error in
            // Apple pattern: Always dispatch callback to main queue for UI updates
            DispatchQueue.main.async {
                AppLogger.info("DEBUG: Authorization callback - success: \(success), error: \(String(describing: error))", category: AppLogger.healthKit)

                if success {
                    AppLogger.info("\(dataType.displayName) authorization granted", category: AppLogger.healthKit)
                    // Update authorization status in singleton
                    HealthKitManager.shared.checkAuthorizationStatus()
                } else {
                    AppLogger.info("\(dataType.displayName) authorization denied", category: AppLogger.healthKit)
                    if let error = error {
                        AppLogger.error("\(dataType.displayName) authorization error", category: AppLogger.healthKit, error: error)
                    } else {
                        AppLogger.warning("\(dataType.displayName) authorization denied with no error - this means Apple dialog never appeared", category: AppLogger.healthKit)
                    }
                }

                completion(success, error)
            }
        }
    }

    // MARK: - Convenience Methods for Individual Data Types

    /// Request weight-specific authorization (preserves existing API)
    static func requestWeightAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        requestAuthorization(for: .weight, completion: completion)
    }

    /// Request hydration-specific authorization (preserves existing API)
    static func requestHydrationAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        requestAuthorization(for: .hydration, completion: completion)
    }

    /// Request sleep-specific authorization (preserves existing API)
    static func requestSleepAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        requestAuthorization(for: .sleep, completion: completion)
    }

    /// Request fasting-specific authorization (workouts for fasting sessions)
    static func requestFastingAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        requestAuthorization(for: .fasting, completion: completion)
    }

    /// Request mindfulness-specific authorization (mindful sessions for mood tracking)
    static func requestMindfulnessAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        requestAuthorization(for: .mindfulness, completion: completion)
    }

    /// Request comprehensive authorization for all data types
    static func requestComprehensiveAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        requestAuthorization(for: .comprehensive, completion: completion)
    }
}