import Combine
import Foundation

@MainActor
protocol WeightSyncCoordinating {
    var statusPublisher: AnyPublisher<WeightSyncStatus, Never> { get }
    func sync(initialImport: Bool)
}

@MainActor
final class WeightSyncCoordinator: WeightSyncCoordinating {
    private let weightManager: WeightManager
    private let healthKitManager: HealthKitManagerProtocol

    private let statusSubject = CurrentValueSubject<WeightSyncStatus, Never>(.idle)
    private var isSyncing = false

    var statusPublisher: AnyPublisher<WeightSyncStatus, Never> {
        statusSubject.eraseToAnyPublisher()
    }

    init(weightManager: WeightManager, healthKitManager: HealthKitManagerProtocol) {
        self.weightManager = weightManager
        self.healthKitManager = healthKitManager
    }

    func sync(initialImport: Bool) {
        guard !isSyncing else { return }
        isSyncing = true
        statusSubject.send(.syncing)

        let startDate = Calendar.current.date(byAdding: .year, value: -10, to: Date()) ?? Date()
        let completion: (Int, Error?) -> Void = { [weak self] count, error in
            guard let self else { return }
            Task { @MainActor in
                self.isSyncing = false
                if let error = error {
                    self.statusSubject.send(.failure(message: error.localizedDescription))
                } else if count > 0 {
                    self.statusSubject.send(.success(newEntries: count))
                } else {
                    self.statusSubject.send(.upToDate)
                }
            }
        }

        if initialImport {
            weightManager.syncFromHealthKitWithReset(startDate: startDate, completion: completion)
        } else {
            weightManager.syncFromHealthKit(startDate: startDate, completion: completion)
        }
    }
}
