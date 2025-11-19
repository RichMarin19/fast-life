import Foundation

/// Represents the current state of a HealthKit weight sync.
enum WeightSyncStatus: Equatable {
    case idle
    case syncing
    case success(newEntries: Int)
    case upToDate
    case failure(message: String)
}
