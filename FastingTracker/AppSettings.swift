import Foundation
import SwiftUI

/// Global application settings following Apple's single source of truth principle
/// Reference: https://developer.apple.com/documentation/swiftui/appstorage
/// Reference: https://developer.apple.com/documentation/swiftui/managing-user-interface-state
final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    // MARK: - Unit Preferences
    // Following Apple @AppStorage pattern for persistent user preferences
    // Reference: https://developer.apple.com/documentation/swiftui/appstorage

    @AppStorage("hydrationUnit") var hydrationUnit: HydrationUnit = .ounces
    @AppStorage("weightUnit") var weightUnit: WeightUnit = .pounds

    // MARK: - Default Tracker (Phase 3 Roadmap Implementation)
    // Following roadmap specification for default start tracker

    @AppStorage("app.defaultTracker") private var defaultTrackerRawValue: String = ""

    @Published var defaultTracker: TrackerType? {
        didSet {
            defaultTrackerRawValue = defaultTracker?.rawValue ?? ""
        }
    }

    private init() {
        // Initialize default tracker from stored raw value
        // Following Apple pattern for enum persistence via raw values
        if !defaultTrackerRawValue.isEmpty {
            defaultTracker = TrackerType(rawValue: defaultTrackerRawValue)
        }
    }
}

// MARK: - Unit Enumerations
// Following Apple naming conventions and CaseIterable for UI selection
// Reference: https://docs.swift.org/swift-book/LanguageGuide/Enumerations.html

enum HydrationUnit: String, CaseIterable, Identifiable {
    case ounces = "oz"
    case milliliters = "ml"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .ounces: return "Fluid Ounces (oz)"
        case .milliliters: return "Milliliters (ml)"
        }
    }

    var abbreviation: String {
        return rawValue
    }

    /// Convert from ounces to this unit
    /// Following standard US fluid ounce conversion: 1 fl oz = 29.5735 ml
    /// Reference: https://www.nist.gov/pml/weights-and-measures/approximate-conversions-us-customary-measures
    func fromOunces(_ ounces: Double) -> Double {
        switch self {
        case .ounces: return ounces
        case .milliliters: return ounces * 29.5735
        }
    }

    /// Convert from this unit to ounces
    func toOunces(_ value: Double) -> Double {
        switch self {
        case .ounces: return value
        case .milliliters: return value / 29.5735
        }
    }
}

enum WeightUnit: String, CaseIterable, Identifiable {
    case pounds = "lbs"
    case kilograms = "kg"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .pounds: return "Pounds (lbs)"
        case .kilograms: return "Kilograms (kg)"
        }
    }

    var abbreviation: String {
        return rawValue
    }

    /// Convert from pounds to this unit
    /// Following standard conversion: 1 lb = 0.453592 kg
    /// Reference: https://www.nist.gov/pml/weights-and-measures/approximate-conversions-us-customary-measures
    func fromPounds(_ pounds: Double) -> Double {
        switch self {
        case .pounds: return pounds
        case .kilograms: return pounds * 0.453592
        }
    }

    /// Convert from this unit to pounds
    func toPounds(_ value: Double) -> Double {
        switch self {
        case .pounds: return value
        case .kilograms: return value / 0.453592
        }
    }
}

// MARK: - Tracker Type (Phase 3 Roadmap Implementation)
// Following roadmap specification exactly as provided

enum TrackerType: String, CaseIterable, Identifiable {
    case weight = "weight"
    case fasting = "fasting"
    case hydration = "hydration"
    case sleep = "sleep"
    case mood = "mood"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .weight: return "Weight"
        case .fasting: return "Fasting"
        case .hydration: return "Hydration"
        case .sleep: return "Sleep"
        case .mood: return "Mood & Energy"
        }
    }

    var systemImage: String {
        switch self {
        case .weight: return "scalemass"
        case .fasting: return "timer"
        case .hydration: return "drop.fill"
        case .sleep: return "bed.double.fill"
        case .mood: return "face.smiling"
        }
    }

    // Luxury SF Symbol icons following luxury spec design guidelines
    // Style: Minimalist line icons, 2pt rounded strokes, 24pt/28pt bounding box
    var icon: String {
        switch self {
        case .weight: return "scalemass.fill"           // Modern scale outline
        case .fasting: return "timer.circle.fill"       // Circular timer design
        case .hydration: return "drop.fill"             // Single water drop silhouette
        case .sleep: return "moon.circle.fill"          // Crescent moon outline
        case .mood: return "face.smiling.fill"          // Simple smile design
        }
    }
}

