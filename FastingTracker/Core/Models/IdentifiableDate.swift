import Foundation

/// Wrapper for Date that conforms to Identifiable protocol
/// Used for SwiftUI sheet presentations and list navigation
/// Following Apple's Identifiable best practices with UUID-based identity
struct IdentifiableDate: Identifiable {
    let id = UUID()
    let date: Date

    init(date: Date) {
        self.date = date
    }
}