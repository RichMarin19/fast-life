import Foundation

/// Time range options for Weight History card filtering
/// Industry Pattern: Apple Health-style time range filtering with performance optimization
/// Default to 1 day for fast loading, expandable to longer ranges on demand
enum WeightHistoryTimeRange: String, CaseIterable, Codable {
    case day = "1 Day"
    case week = "7 Days"
    case month = "30 Days"
    case quarter = "90 Days"
    case year = "1 Year"
    case allTime = "All Time"
    case custom = "Custom"

    /// Calendar component and value for date calculation
    var dateComponents: (component: Calendar.Component, value: Int)? {
        switch self {
        case .day:
            return (.day, -1)
        case .week:
            return (.day, -7)
        case .month:
            return (.day, -30)
        case .quarter:
            return (.day, -90)
        case .year:
            return (.year, -1)
        case .allTime, .custom:
            return nil
        }
    }

    /// User-friendly display name
    var displayName: String {
        return self.rawValue
    }
}
