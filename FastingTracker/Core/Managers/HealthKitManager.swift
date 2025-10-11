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

    // MARK: - TODO: Add Other Services
    // TODO: Add hydration service delegation
    // TODO: Add sleep service delegation
    // TODO: Add fasting service delegation
    // TODO: Add observer management service
}