import Foundation

enum WeightSyncStatus: Equatable {
    case idle
    case syncing
    case success(newEntries: Int)
    case upToDate
    case failure(message: String)
}
