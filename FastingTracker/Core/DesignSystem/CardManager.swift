import Foundation
import Combine

// MARK: - Protocols

@MainActor
protocol TrackerCardManaging: AnyObject {
    var cardPreferences: [CardPreference<TrackerCardType>] { get }
    var objectWillChange: ObservableObjectPublisher { get }

    func getVisibleCardsInOrder() -> [TrackerCardType]
    func isCardVisible(_ card: TrackerCardType) -> Bool
    func showCard(_ card: TrackerCardType)
    func hideCard(_ card: TrackerCardType)
}

// MARK: - Generic Card Manager

/// Unified card manager that handles ALL card types (TrackerCardType, ProgressStoryCardType, ControlCenterCardType, etc.)
/// Replaces: TrackerCardManager, ProgressStoryCardManager (Phase v1.4a)
/// Future: Will replace Control Center custom system (Phase v1.4c)
///
/// Industry Pattern: Generic manager with protocol-oriented design
/// Reference: Apple Health (single card system), SwiftUI State<T>, Google Calendar (generic event manager)
///
/// ARCHITECTURE DECISION (ADR-001 - October 21, 2025):
/// This generic manager unifies duplicate card management systems across the app.
///
/// Benefits:
/// - ✅ DRY (Don't Repeat Yourself) - Write logic once, works everywhere
/// - ✅ SSOT (Single Source of Truth) - One implementation to maintain
/// - ✅ Industry Standard - Apple/Google/Stripe use this pattern
/// - ✅ Future-Proof - Automatically works for all 5 trackers
/// - ✅ Type-Safe - Swift generics prevent mistakes at compile time
///
/// Usage:
/// ```swift
/// // For main tracker cards
/// let trackerCards = CardManager<TrackerCardType>(preferencesKey: "trackerCardPreferences_v1")
/// trackerCards.isCardVisible(.currentWeight)
/// trackerCards.reorderCards(from: 0, to: 2)
///
/// // For Progress Story cards
/// let progressCards = CardManager<ProgressStoryCardType>(preferencesKey: "progressStoryCardPreferences_v1")
/// progressCards.isCardVisible(.sevenDay)
/// progressCards.hideCard(.banner)
/// ```
@MainActor
class CardManager<CardType: CardTypeProtocol>: ObservableObject {
    // MARK: - Published State

    /// All card preferences for this card type
    /// Published for reactive UI updates (SwiftUI observes changes)
    @Published private(set) var cardPreferences: [CardPreference<CardType>] = []

    // MARK: - Private Properties

    private let userDefaults = UserDefaults.standard
    private let cardPreferencesKey: String

    // MARK: - Initialization

    /// Initialize card manager with a unique UserDefaults key
    /// - Parameter preferencesKey: Unique key for UserDefaults persistence (e.g., "trackerCardPreferences_v1")
    init(preferencesKey: String) {
        self.cardPreferencesKey = preferencesKey
        loadCardPreferences()
    }

    // MARK: - Public API - Visibility

    /// Check if a card is currently visible
    /// - Parameter cardType: The card type to check
    /// - Returns: True if visible, false if hidden
    func isCardVisible(_ cardType: CardType) -> Bool {
        if let preference = cardPreferences.first(where: { $0.id == cardType.rawValue }) {
            return preference.isVisible
        }
        return true  // Default: visible
    }

    /// Set visibility for a card
    /// - Parameters:
    ///   - cardType: The card type to update
    ///   - isVisible: True to show, false to hide
    func setCardVisibility(_ cardType: CardType, isVisible: Bool) {
        if let index = cardPreferences.firstIndex(where: { $0.id == cardType.rawValue }) {
            cardPreferences[index].isVisible = isVisible
        } else {
            // Create new preference if it doesn't exist
            let sortOrder = cardPreferences.count
            let newPreference = CardPreference(
                cardType: cardType,
                isVisible: isVisible,
                isExpanded: true,
                sortOrder: sortOrder
            )
            cardPreferences.append(newPreference)
        }

        saveCardPreferences()
    }

    /// Hide a card (convenience method)
    /// - Parameter cardType: The card type to hide
    func hideCard(_ cardType: CardType) {
        setCardVisibility(cardType, isVisible: false)
    }

    /// Show a card (convenience method)
    /// - Parameter cardType: The card type to show
    func showCard(_ cardType: CardType) {
        setCardVisibility(cardType, isVisible: true)
    }

    // MARK: - Public API - Expansion (Layer 4)

    /// Check if a card is currently expanded
    /// - Parameter cardType: The card type to check
    /// - Returns: True if expanded, false if collapsed
    func isCardExpanded(_ cardType: CardType) -> Bool {
        if let preference = cardPreferences.first(where: { $0.id == cardType.rawValue }) {
            return preference.isExpanded
        }
        return true  // Default: expanded
    }

    /// Set expansion state for a card
    /// - Parameters:
    ///   - cardType: The card type to update
    ///   - isExpanded: True to expand, false to collapse
    func setCardExpanded(_ cardType: CardType, isExpanded: Bool) {
        if let index = cardPreferences.firstIndex(where: { $0.id == cardType.rawValue }) {
            cardPreferences[index].isExpanded = isExpanded
        } else {
            // Create new preference if it doesn't exist
            let sortOrder = cardPreferences.count
            let newPreference = CardPreference(
                cardType: cardType,
                isVisible: true,
                isExpanded: isExpanded,
                sortOrder: sortOrder
            )
            cardPreferences.append(newPreference)
        }

        saveCardPreferences()
    }

    /// Toggle expansion state for a card
    /// - Parameter cardType: The card type to toggle
    func toggleCardExpansion(_ cardType: CardType) {
        let currentState = isCardExpanded(cardType)
        setCardExpanded(cardType, isExpanded: !currentState)
    }

    // MARK: - Public API - Ordering (Layer 5)

    /// Get sort order for a card
    /// - Parameter cardType: The card type to check
    /// - Returns: Sort order index (0 = first position)
    func getCardOrder(_ cardType: CardType) -> Int {
        if let preference = cardPreferences.first(where: { $0.id == cardType.rawValue }) {
            return preference.sortOrder
        }
        // Default: use enum case order
        if let index = CardType.allCases.firstIndex(of: cardType) {
            return CardType.allCases.distance(from: CardType.allCases.startIndex, to: index)
        }
        return 0
    }

    /// Reorder cards (used when user drags to reorder)
    /// - Parameters:
    ///   - sourceIndex: Starting position (0-based)
    ///   - destinationIndex: Target position (0-based)
    ///
    /// Example: reorderCards(from: 0, to: 2) moves first card to third position
    ///
    /// ✅ ONE IMPLEMENTATION - Works for ALL card types (TrackerCardType, ProgressStoryCardType, etc.)
    /// This is why we unified the managers - add this method once, both systems get it!
    func reorderCards(from sourceIndex: Int, to destinationIndex: Int) {
        guard sourceIndex != destinationIndex,
              sourceIndex < cardPreferences.count,
              destinationIndex < cardPreferences.count else {
            return
        }

        // Move card in array
        let movedCard = cardPreferences.remove(at: sourceIndex)
        cardPreferences.insert(movedCard, at: destinationIndex)

        // Update sortOrder for all cards to match new positions
        for (index, _) in cardPreferences.enumerated() {
            cardPreferences[index].sortOrder = index
        }

        saveCardPreferences()
    }

    /// Get all visible cards in sorted order
    /// - Returns: Array of card types that are visible, sorted by sortOrder
    ///
    /// Use this for rendering cards in correct order:
    /// ```swift
    /// ForEach(cardManager.getVisibleCardsInOrder()) { cardType in
    ///     renderCard(cardType)
    /// }
    /// ```
    func getVisibleCardsInOrder() -> [CardType] {
        return cardPreferences
            .filter { $0.isVisible }
            .sorted { $0.sortOrder < $1.sortOrder }
            .compactMap { CardType(rawValue: $0.id) }
    }

    // MARK: - Public API - Reset

    /// Reset all cards to default state (visible, expanded, default order)
    /// Used by "Restore All" button in Control Center
    func resetAllCards() {
        cardPreferences.removeAll()
        saveCardPreferences()
    }

    // MARK: - Persistence

    /// Load card preferences from UserDefaults
    private func loadCardPreferences() {
        guard let data = userDefaults.data(forKey: cardPreferencesKey),
              let decoded = try? JSONDecoder().decode([CardPreference<CardType>].self, from: data) else {
            // No saved preferences - initialize with defaults
            initializeDefaults()
            return
        }

        var normalizedPreferences: [CardPreference<CardType>] = []
        var seenIDs = Set<String>()

        for var preference in decoded {
            preference.id = normalizePreferenceID(preference.id)
            guard CardType(rawValue: preference.id) != nil else { continue }
            guard !seenIDs.contains(preference.id) else { continue }

            seenIDs.insert(preference.id)
            normalizedPreferences.append(preference)
        }

        // DATA MIGRATION (Enhancement 8 - Oct 31, 2025):
        // Filter out stale preferences for card types that no longer exist in enum
        // Example: .milestone card was removed in Enhancement 7, but old preferences persist
        // This caused index mismatches during drag-to-reorder operations
        cardPreferences = normalizedPreferences

        // Migration: Ensure all current card types have preferences
        // Handles case where new card types are added to enum
        ensureAllCardsHavePreferences()
    }

    /// Save card preferences to UserDefaults
    private func saveCardPreferences() {
        guard let encoded = try? JSONEncoder().encode(cardPreferences) else {
            AppLogger.error("Failed to encode card preferences for \(cardPreferencesKey)", category: AppLogger.persistence)
            return
        }

        userDefaults.set(encoded, forKey: cardPreferencesKey)
    }

    /// Initialize default preferences for all cards
    /// Called on first launch when no saved preferences exist
    private func initializeDefaults() {
        cardPreferences = CardType.allCases.enumerated().map { (index, cardType) in
            let isVisibleByDefault = defaultVisibility(for: cardType)
            return CardPreference(cardType: cardType, isVisible: isVisibleByDefault, sortOrder: index)
        }

        saveCardPreferences()
    }

    /// Ensure all card types have preferences (handles enum additions)
    /// Called during load to migrate users who have old preferences
    private func ensureAllCardsHavePreferences() {
        var hasChanges = false

        for cardType in CardType.allCases {
            if !cardPreferences.contains(where: { $0.id == cardType.rawValue }) {
                let newPreference = CardPreference(
                    cardType: cardType,
                    isVisible: defaultVisibility(for: cardType),
                    sortOrder: cardPreferences.count
                )
                cardPreferences.append(newPreference)
                hasChanges = true
            }
        }

        if hasChanges {
            saveCardPreferences()
        }
    }

    private func normalizePreferenceID(_ id: String) -> String {
        if CardType.self == ProgressStoryCardType.self {
            switch id {
            case "progress_story_7day_card", "progress_story_30day_card":
                return "progress_story_trend_snapshot_card"
            default:
                return id
            }
        }
        return id
    }
}

// MARK: - Generic Card Preference Model

/// Generic model for persisting card preferences
/// Works with any CardType that conforms to CardTypeProtocol
///
/// Industry Pattern: JSON serialization for UserDefaults storage
/// Reference: Apple Foundation - Codable (Swift 4+)
///
/// Stored in UserDefaults as JSON array:
/// ```json
/// [
///   {"id": "current_weight_card", "isVisible": true, "isExpanded": true, "sortOrder": 0},
///   {"id": "chart_card", "isVisible": true, "isExpanded": false, "sortOrder": 1},
///   {"id": "stats_card", "isVisible": true, "isExpanded": true, "sortOrder": 2}
/// ]
/// ```
/// Note: milestone_card removed in Enhancement 7 (redundant with Current Weight Card)
struct CardPreference<CardType: CardTypeProtocol>: Codable, Identifiable {
    /// Unique identifier (cardType.rawValue)
    var id: String

    /// Is this card visible on screen?
    var isVisible: Bool

    /// Is this card expanded? (Layer 4 feature)
    var isExpanded: Bool

    /// Sort order (0 = first position)
    var sortOrder: Int

    /// Initialize with card type
    /// - Parameters:
    ///   - cardType: The card type (must conform to CardTypeProtocol)
    ///   - isVisible: True to show, false to hide (default: true)
    ///   - isExpanded: True to expand, false to collapse (default: true)
    ///   - sortOrder: Position in list (0 = first)
    init(cardType: CardType, isVisible: Bool = true, isExpanded: Bool = true, sortOrder: Int) {
        self.id = cardType.rawValue
        self.isVisible = isVisible
        self.isExpanded = isExpanded
        self.sortOrder = sortOrder
    }
}

// MARK: - Convenience Singletons (Non-Generic Wrappers)

/// Singleton for tracker cards (Current Weight, Chart, Stats, etc.)
/// Replaces: TrackerCardManager.shared
///
/// Industry Pattern: Non-generic wrapper class enables static stored property (Swift limitation workaround)
/// Reference: Apple Foundation - URLSession.shared, NotificationCenter.default use this pattern
@MainActor
final class TrackerCards {
    static let shared = CardManager<TrackerCardType>(preferencesKey: "trackerCardPreferences_v1")
    private init() {}
}

/// Singleton for Progress Story cards (7-Day, 30-Day, Banner, etc.)
/// Replaces: ProgressStoryCardManager.shared
///
/// Industry Pattern: Non-generic wrapper class enables static stored property (Swift limitation workaround)
/// Reference: Apple Foundation - URLSession.shared, NotificationCenter.default use this pattern
@MainActor
final class ProgressStoryCards {
    static let shared = CardManager<ProgressStoryCardType>(preferencesKey: "progressStoryCardPreferences_v1")
    private init() {}
}

private extension CardManager {
    func defaultVisibility(for cardType: CardType) -> Bool {
        if let trackerCard = cardType as? TrackerCardType, trackerCard == .history {
            return false
        }
        if let progressCard = cardType as? ProgressStoryCardType, progressCard == .banner {
            return false
        }
        return true
    }
}

@MainActor
extension CardManager: TrackerCardManaging where CardType == TrackerCardType {}
