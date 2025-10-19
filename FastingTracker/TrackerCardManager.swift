import Foundation
import Combine

// MARK: - Tracker Card Manager

/// Centralized manager for all tracker card state (visibility, order, expansion)
/// Industry Pattern: Singleton manager for app-wide feature toggles
/// Reference: Apple Health app - Card management system
/// Reference: Spotify app - Playlist ordering and visibility
@MainActor
class TrackerCardManager: ObservableObject {
    // MARK: - Singleton

    static let shared = TrackerCardManager()

    // MARK: - Published State

    /// All card preferences across the app
    /// Published for reactive UI updates
    @Published private(set) var cardPreferences: [CardPreference] = []

    // MARK: - Private Properties

    private let userDefaults = UserDefaults.standard
    private let cardPreferencesKey = "trackerCardPreferences_v1"

    // Legacy UserDefaults keys (for backwards compatibility migration only)
    // Will be removed after migration period
    private let legacyKeys: [TrackerCardType: String] = [
        .currentWeight: "showCurrentWeightCard",
        .milestone: "showMilestoneCard",
        .chart: "showChartCard",
        .stats: "showStatsCard",
        .history: "showHistoryCard"
    ]

    // MARK: - Initialization

    private init() {
        loadCardPreferences()
    }

    // MARK: - Public API - Visibility

    /// Check if a card is currently visible
    func isCardVisible(_ cardType: TrackerCardType) -> Bool {
        // Check new system first
        if let preference = cardPreferences.first(where: { $0.id == cardType.rawValue }) {
            return preference.isVisible
        }

        // BACKWARDS COMPATIBILITY: Fall back to legacy UserDefaults keys (ONE-TIME MIGRATION)
        // This ensures existing user preferences are preserved during initial load
        if let legacyKey = legacyKeys[cardType] {
            let legacyVisible = userDefaults.object(forKey: legacyKey) as? Bool ?? true
            return legacyVisible
        }

        return true  // Default: visible
    }

    /// Set visibility for a card
    func setCardVisibility(_ cardType: TrackerCardType, isVisible: Bool) {
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

        // REMOVED: Legacy UserDefaults write - all code now uses TrackerCardManager
        // Single source of truth: CardPreference JSON in UserDefaults

        saveCardPreferences()
    }

    /// Hide a card (convenience method)
    func hideCard(_ cardType: TrackerCardType) {
        setCardVisibility(cardType, isVisible: false)
    }

    /// Show a card (convenience method)
    func showCard(_ cardType: TrackerCardType) {
        setCardVisibility(cardType, isVisible: true)
    }

    // MARK: - Public API - Expansion

    /// Check if a card is currently expanded
    func isCardExpanded(_ cardType: TrackerCardType) -> Bool {
        if let preference = cardPreferences.first(where: { $0.id == cardType.rawValue }) {
            return preference.isExpanded
        }
        return true  // Default: expanded
    }

    /// Set expansion state for a card
    func setCardExpanded(_ cardType: TrackerCardType, isExpanded: Bool) {
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
    func toggleCardExpansion(_ cardType: TrackerCardType) {
        let currentState = isCardExpanded(cardType)
        setCardExpanded(cardType, isExpanded: !currentState)
    }

    // MARK: - Public API - Ordering

    /// Get sort order for a card
    func getCardOrder(_ cardType: TrackerCardType) -> Int {
        if let preference = cardPreferences.first(where: { $0.id == cardType.rawValue }) {
            return preference.sortOrder
        }
        // Default: use enum case order
        return TrackerCardType.allCases.firstIndex(of: cardType) ?? 0
    }

    /// Reorder cards (used when user drags to reorder)
    func reorderCards(from sourceIndex: Int, to destinationIndex: Int) {
        guard sourceIndex != destinationIndex,
              sourceIndex < cardPreferences.count,
              destinationIndex < cardPreferences.count else {
            return
        }

        // Move card in array
        let movedCard = cardPreferences.remove(at: sourceIndex)
        cardPreferences.insert(movedCard, at: destinationIndex)

        // Update sortOrder for all cards
        for (index, _) in cardPreferences.enumerated() {
            cardPreferences[index].sortOrder = index
        }

        saveCardPreferences()
    }

    /// Get all visible cards in sorted order
    func getVisibleCardsInOrder() -> [TrackerCardType] {
        return cardPreferences
            .filter { $0.isVisible }
            .sorted { $0.sortOrder < $1.sortOrder }
            .compactMap { TrackerCardType(rawValue: $0.id) }
    }

    // MARK: - Public API - Reset

    /// Reset all cards to default state (visible, expanded, default order)
    func resetAllCards() {
        cardPreferences.removeAll()

        // REMOVED: Legacy UserDefaults cleanup - no longer writing to legacy keys
        // Migration users: Legacy keys will naturally be ignored after first load

        saveCardPreferences()
    }

    // MARK: - Persistence

    /// Load card preferences from UserDefaults
    private func loadCardPreferences() {
        guard let data = userDefaults.data(forKey: cardPreferencesKey),
              let decoded = try? JSONDecoder().decode([CardPreference].self, from: data) else {
            // No saved preferences - initialize with defaults
            initializeDefaults()
            return
        }

        cardPreferences = decoded

        // Migration: Ensure all current card types have preferences
        ensureAllCardsHavePreferences()
    }

    /// Save card preferences to UserDefaults
    private func saveCardPreferences() {
        guard let encoded = try? JSONEncoder().encode(cardPreferences) else {
            AppLogger.error("Failed to encode card preferences", category: AppLogger.persistence)
            return
        }

        userDefaults.set(encoded, forKey: cardPreferencesKey)
    }

    /// Initialize default preferences for all cards
    private func initializeDefaults() {
        cardPreferences = TrackerCardType.allCases.enumerated().map { (index, cardType) in
            // BACKWARDS COMPATIBILITY: Check if legacy UserDefaults key exists (ONE-TIME MIGRATION)
            var legacyVisible = true
            if let legacyKey = legacyKeys[cardType] {
                legacyVisible = userDefaults.object(forKey: legacyKey) as? Bool ?? true
            }

            return CardPreference(
                cardType: cardType,
                isVisible: legacyVisible,
                isExpanded: true,
                sortOrder: index
            )
        }

        saveCardPreferences()
    }

    /// Ensure all card types have preferences (handles enum additions)
    private func ensureAllCardsHavePreferences() {
        var hasChanges = false

        for cardType in TrackerCardType.allCases {
            if !cardPreferences.contains(where: { $0.id == cardType.rawValue }) {
                // New card type - add with default preferences
                var legacyVisible = true
                if let legacyKey = legacyKeys[cardType] {
                    legacyVisible = userDefaults.object(forKey: legacyKey) as? Bool ?? true
                }

                let newPreference = CardPreference(
                    cardType: cardType,
                    isVisible: legacyVisible,
                    isExpanded: true,
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
}
