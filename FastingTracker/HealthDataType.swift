import SwiftUI

/// Health data types available for granular selection
/// Following Apple HealthKit categorization and iOS Health app patterns
/// Reference: https://developer.apple.com/documentation/healthkit/hkobjecttype
enum HealthDataType: String, CaseIterable {
    case weight = "weight"
    case hydration = "hydration"
    case sleep = "sleep"
    case fasting = "fasting"

    var displayName: String {
        switch self {
        case .weight: return "Weight & Body Measurements"
        case .hydration: return "Hydration & Water Intake"
        case .sleep: return "Sleep Analysis"
        case .fasting: return "Fasting Sessions"
        }
    }

    var description: String {
        switch self {
        case .weight: return "Track weight, BMI, and body fat percentage"
        case .hydration: return "Log water, coffee, tea, and other drinks"
        case .sleep: return "Monitor sleep patterns and duration"
        case .fasting: return "Record intermittent fasting sessions"
        }
    }

    var iconName: String {
        switch self {
        case .weight: return "scalemass"
        case .hydration: return "drop.fill"
        case .sleep: return "bed.double.fill"
        case .fasting: return "timer"
        }
    }

    var color: Color {
        switch self {
        case .weight: return .blue
        case .hydration: return .cyan
        case .sleep: return .purple
        case .fasting: return .green
        }
    }
}