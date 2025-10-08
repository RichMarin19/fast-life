import Foundation

/// Manages user preferences for health data syncing
/// Following Apple Data Management best practices with UserDefaults
/// Reference: https://developer.apple.com/documentation/foundation/userdefaults
class HealthDataPreferences: ObservableObject {
    static let shared = HealthDataPreferences()

    private let userDefaults = UserDefaults.standard
    private let hasShownSelectionKey = "hasShownHealthDataSelection"
    private let enabledDataTypesKey = "enabledHealthDataTypes"

    private init() {}

    // MARK: - Selection Flow State

    /// Whether the user has completed the health data selection flow
    var hasShownSelection: Bool {
        get { userDefaults.bool(forKey: hasShownSelectionKey) }
        set { userDefaults.set(newValue, forKey: hasShownSelectionKey) }
    }

    /// Set of health data types the user has enabled
    var enabledDataTypes: Set<HealthDataType> {
        get {
            guard let rawValues = userDefaults.array(forKey: enabledDataTypesKey) as? [String] else {
                return []
            }
            return Set(rawValues.compactMap { HealthDataType(rawValue: $0) })
        }
        set {
            let rawValues = newValue.map { $0.rawValue }
            userDefaults.set(rawValues, forKey: enabledDataTypesKey)
        }
    }

    // MARK: - Convenience Methods

    /// Check if a specific data type is enabled
    func isEnabled(_ dataType: HealthDataType) -> Bool {
        return enabledDataTypes.contains(dataType)
    }

    /// Check if user needs to see selection screen
    /// True if they haven't seen it AND haven't authorized any health data
    func shouldShowSelection() -> Bool {
        return !hasShownSelection && !HealthKitManager.shared.isAuthorized
    }

    /// Mark selection as completed and save preferences
    func completeSelection(with selectedTypes: Set<HealthDataType>) {
        enabledDataTypes = selectedTypes
        hasShownSelection = true

        AppLogger.info("Health data selection completed", category: AppLogger.general)
        AppLogger.debug("Selected types: \(selectedTypes.map { $0.rawValue })", category: AppLogger.general)
    }

    /// Reset all preferences (for testing/debugging)
    func reset() {
        userDefaults.removeObject(forKey: hasShownSelectionKey)
        userDefaults.removeObject(forKey: enabledDataTypesKey)
        AppLogger.info("Health data preferences reset", category: AppLogger.general)
    }
}

// MARK: - Authorization Helper

extension HealthDataPreferences {

    /// Request authorization for user's selected data types
    /// Following Apple HealthKit Programming Guide for granular authorization
    /// Reference: https://developer.apple.com/documentation/healthkit/protecting_user_privacy
    func requestSelectedAuthorizations(completion: @escaping (Bool, Error?) -> Void) {
        let selectedTypes = enabledDataTypes

        guard !selectedTypes.isEmpty else {
            AppLogger.info("No health data types selected, skipping authorization", category: AppLogger.healthKit)
            completion(true, nil)
            return
        }

        AppLogger.info("Requesting authorization for selected data types", category: AppLogger.healthKit)

        // Use appropriate authorization method based on selection
        if selectedTypes.count == 1, let singleType = selectedTypes.first {
            requestSingleTypeAuthorization(singleType, completion: completion)
        } else {
            requestMultipleTypeAuthorization(selectedTypes, completion: completion)
        }
    }

    private func requestSingleTypeAuthorization(_ dataType: HealthDataType, completion: @escaping (Bool, Error?) -> Void) {
        switch dataType {
        case .weight:
            HealthKitManager.shared.requestWeightAuthorization(completion: completion)
        case .hydration:
            HealthKitManager.shared.requestHydrationAuthorization(completion: completion)
        case .sleep:
            HealthKitManager.shared.requestSleepAuthorization(completion: completion)
        case .fasting:
            HealthKitManager.shared.requestFastingAuthorization(completion: completion)
        }
    }

    private func requestMultipleTypeAuthorization(_ dataTypes: Set<HealthDataType>, completion: @escaping (Bool, Error?) -> Void) {
        // For multiple types, use comprehensive authorization
        // This is more efficient than individual requests
        HealthKitManager.shared.requestAuthorization(completion: completion)
    }
}

#if DEBUG
// MARK: - Testing Support
extension HealthDataPreferences {
    /// For testing: simulate user completing onboarding with skip
    func simulateSkipOnboarding() {
        hasShownSelection = false
        enabledDataTypes = []
    }

    /// For testing: simulate user completing onboarding with full sync
    func simulateFullSyncOnboarding() {
        hasShownSelection = true
        enabledDataTypes = Set(HealthDataType.allCases)
    }
}
#endif