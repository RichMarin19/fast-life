import Foundation
import Combine

// MARK: - Progress Story Card Manager

/// Centralized manager for all Progress Story card state (visibility, order)
/// Industry Pattern: Singleton manager for app-wide feature toggles
/// Reference: Apple Health app - Card management system
/// Same pattern as TrackerCardManager but for Progress Story cards
@MainActor
class ProgressStoryCardManager: ObservableObject {
    // MARK: - Singleton

    static let shared = ProgressStoryCardManager()

    // MARK: - Published State

    /// All Progress Story card preferences
    /// Published for reactive UI updates
    @Published private(set) var cardPreferences: [LegacyProgressStoryCardPreference] = []

    // MARK: - Private Properties

    private let userDefaults = UserDefaults.standard
    private let cardPreferencesKey = "progressStoryCardPreferences_v1"

    // MARK: - Initialization

    private init() {
        loadCardPreferences()
        migrateFromContentOptOutManager()
    }

    // MARK: - Public API - Visibility

    /// Check if a Progress Story card is currently visible
    func isCardVisible(_ cardType: ProgressStoryCardType) -> Bool {
        // Check if preference exists
        if let preference = cardPreferences.first(where: { $0.id == cardType.rawValue }) {
            return preference.isVisible
        }

        return true  // Default: visible
    }

    /// Set visibility for a Progress Story card
    func setCardVisibility(_ cardType: ProgressStoryCardType, isVisible: Bool) {
        if let index = cardPreferences.firstIndex(where: { $0.id == cardType.rawValue }) {
            cardPreferences[index].isVisible = isVisible
        } else {
            // Create new preference if it doesn't exist
            let sortOrder = cardPreferences.count
            let newPreference = LegacyProgressStoryCardPreference(
                cardType: cardType,
                isVisible: isVisible,
                sortOrder: sortOrder
            )
            cardPreferences.append(newPreference)
        }

        saveCardPreferences()
    }

    /// Hide a card (convenience method)
    func hideCard(_ cardType: ProgressStoryCardType) {
        setCardVisibility(cardType, isVisible: false)
    }

    /// Show a card (convenience method)
    func showCard(_ cardType: ProgressStoryCardType) {
        setCardVisibility(cardType, isVisible: true)
    }

    // MARK: - Public API - Ordering

    /// Get sort order for a card
    func getCardOrder(_ cardType: ProgressStoryCardType) -> Int {
        if let preference = cardPreferences.first(where: { $0.id == cardType.rawValue }) {
            return preference.sortOrder
        }
        // Default: use enum case order
        return ProgressStoryCardType.allCases.firstIndex(of: cardType) ?? 0
    }

    /// Get all visible cards in sorted order
    func getVisibleCardsInOrder() -> [ProgressStoryCardType] {
        return cardPreferences
            .filter { $0.isVisible }
            .sorted { $0.sortOrder < $1.sortOrder }
            .compactMap { ProgressStoryCardType(rawValue: $0.id) }
    }

    // MARK: - Public API - Reset

    /// Reset all cards to default state (visible, default order)
    func resetAllCards() {
        cardPreferences.removeAll()
        saveCardPreferences()
    }

    // MARK: - Persistence

    /// Load card preferences from UserDefaults
    private func loadCardPreferences() {
        guard let data = userDefaults.data(forKey: cardPreferencesKey),
              let decoded = try? JSONDecoder().decode([LegacyProgressStoryCardPreference].self, from: data) else {
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
            AppLogger.error("Failed to encode Progress Story card preferences", category: AppLogger.persistence)
            return
        }

        userDefaults.set(encoded, forKey: cardPreferencesKey)
    }

    /// Initialize default preferences for all Progress Story cards
    private func initializeDefaults() {
        cardPreferences = ProgressStoryCardType.allCases.enumerated().map { (index, cardType) in
            return LegacyProgressStoryCardPreference(
                cardType: cardType,
                isVisible: true,
                sortOrder: index
            )
        }

        saveCardPreferences()
    }

    /// Ensure all card types have preferences (handles enum additions)
    private func ensureAllCardsHavePreferences() {
        var hasChanges = false

        for cardType in ProgressStoryCardType.allCases {
            if !cardPreferences.contains(where: { $0.id == cardType.rawValue }) {
                // New card type - add with default preferences
                let newPreference = LegacyProgressStoryCardPreference(
                    cardType: cardType,
                    isVisible: true,
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

    // MARK: - Migration

    /// Migrate old hidden cards from ContentOptOutManager to ProgressStoryCardManager
    /// Legacy content IDs from old system (before ProgressStoryCardManager existed)
    /// These cards were hidden via ContentOptOutManager and need to be moved to the new system
    /// RUNS EVERY TIME: Continuously cleans up any Progress Story cards in old system
    private func migrateFromContentOptOutManager() {
        // Define mapping: Old ContentOptOutManager ID → New ProgressStoryCardType
        let legacyCardMapping: [String: ProgressStoryCardType] = [
            "progress_story_7day_v1": .sevenDay,
            "progress_story_30day_v1": .thirtyDay,
            "progress_story_banner_v1": .banner,
            "progress_story_recap_v1": .recap,
            "progress_story_tip_v1": .didYouKnow
        ]

        // Access ContentOptOutManager to check for old hidden cards
        let optOutManager = ContentOptOutManager.shared
        var hasChanges = false

        // Check each legacy card ID and clean up duplicates
        // RUNS EVERY TIME to ensure Progress Story cards never stay in old system
        for (legacyID, cardType) in legacyCardMapping {
            // If card is in old system, move it to new system
            if optOutManager.isContentOptedOut(id: legacyID) {
                // Hide card in new system (if not already hidden)
                if isCardVisible(cardType) {
                    hideCard(cardType)
                }
                hasChanges = true

                // Remove from old system (cleanup)
                optOutManager.optInContent(id: legacyID)

                AppLogger.debug("Cleaned up Progress Story card '\(cardType.displayName)' from old ContentOptOutManager", category: AppLogger.persistence)
            }
        }

        if hasChanges {
            AppLogger.info("Cleaned up \(hasChanges ? "some" : "no") Progress Story cards from ContentOptOutManager", category: AppLogger.persistence)
        }
    }
}
