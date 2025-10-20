import Foundation

// MARK: - Tracker Card Protocol

/// Protocol for all tracker cards (Weight, Fasting, Hydration, Sleep, Mood)
/// Industry Pattern: Protocol-oriented design for polymorphic card management
/// Reference: Apple Swift - Protocol-Oriented Programming (WWDC 2015)
/// Reference: Design Patterns - Strategy Pattern (Gang of Four)
protocol TrackerCard {
    /// Unique identifier for this card type
    /// Used for persistence and tracking
    var cardType: TrackerCardType { get }

    /// Whether this card is currently visible
    /// Default: true (shown)
    var isVisible: Bool { get set }

    /// Whether this card is expanded (for expand/collapse feature)
    /// Default: true (expanded)
    var isExpanded: Bool { get set }

    /// Sort order for this card (lower number = higher priority)
    /// Default: based on enum case order
    var sortOrder: Int { get set }

    /// Whether this card can be hidden by user
    /// Default: true (can be hidden)
    var canBeHidden: Bool { get }

    /// Whether this card can be reordered by user
    /// Default: true (can be reordered)
    var canBeReordered: Bool { get }

    /// Whether this card can be collapsed by user
    /// Default: true (can be collapsed)
    var canBeCollapsed: Bool { get }
}

// MARK: - Default Implementations

extension TrackerCard {
    /// Default: All cards can be hidden
    var canBeHidden: Bool { true }

    /// Default: All cards can be reordered
    var canBeReordered: Bool { true }

    /// Default: All cards can be collapsed
    var canBeCollapsed: Bool { true }
}

// MARK: - Card Preference Model

/// Codable model for persisting card preferences
/// Industry Pattern: JSON serialization for UserDefaults storage
/// Reference: Apple Foundation - Codable (Swift 4+)
struct CardPreference: Codable, Identifiable {
    let id: String  // cardType.rawValue
    var isVisible: Bool
    var isExpanded: Bool
    var sortOrder: Int

    init(cardType: TrackerCardType, isVisible: Bool = true, isExpanded: Bool = true, sortOrder: Int) {
        self.id = cardType.rawValue
        self.isVisible = isVisible
        self.isExpanded = isExpanded
        self.sortOrder = sortOrder
    }
}

/// Codable model for persisting Progress Story card preferences
/// Same pattern as CardPreference but for Progress Story cards
/// Industry Pattern: JSON serialization for UserDefaults storage
struct ProgressStoryCardPreference: Codable, Identifiable {
    let id: String  // cardType.rawValue
    var isVisible: Bool
    var sortOrder: Int

    init(cardType: ProgressStoryCardType, isVisible: Bool = true, sortOrder: Int) {
        self.id = cardType.rawValue
        self.isVisible = isVisible
        self.sortOrder = sortOrder
    }
}
