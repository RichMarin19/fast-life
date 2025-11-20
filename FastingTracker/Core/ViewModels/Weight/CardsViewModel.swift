import SwiftUI
import Combine

/// ViewModel for Weight Control Center Card Management
/// Handles card order, expansion state, and drag/drop interactions
/// Extracted from WeightControlCenterViewModel as part of Phase 8.9 Phase 2
/// Reference: HANDOFF.md - Weight Tracker Refactoring
@MainActor
class CardsViewModel: ObservableObject {
    // MARK: - Published State

    /// Current order of cards in the control center
    @Published var cardOrder: [ControlCenterCardType] = [.goals, .notifications, .insights, .sync, .history, .dataManagement, .experience]

    /// Card currently being dragged (for reordering)
    @Published var draggedCard: ControlCenterCardType?

    /// Set of expanded card IDs (collapsed cards not in set)
    @Published var expandedCards: Set<String> = []

    // MARK: - Private Properties

    private let userDefaults = UserDefaults.standard
    private let cardOrderKey = "weightControlCenterCardOrder"
    private let expandedCardsKey = "controlCenterExpandedCards"

    // MARK: - Initialization

    init() {
        loadCardOrder()
        loadExpandedCards()
    }

    // MARK: - Card Expansion

    /// Check if a card is currently expanded
    func isCardExpanded(_ cardType: ControlCenterCardType) -> Bool {
        return expandedCards.contains(cardType.rawValue)
    }

    /// Toggle expansion state for a card
    func toggleCardExpansion(_ cardType: ControlCenterCardType) {
        if expandedCards.contains(cardType.rawValue) {
            expandedCards.remove(cardType.rawValue)
        } else {
            expandedCards.insert(cardType.rawValue)
        }
        saveExpandedCards()
    }

    // MARK: - Persistence

    /// Load expanded cards from UserDefaults
    private func loadExpandedCards() {
        if let data = userDefaults.data(forKey: expandedCardsKey),
           let decoded = try? JSONDecoder().decode(Set<String>.self, from: data) {
            expandedCards = decoded
        } else {
            // Default: All cards expanded on first launch
            expandedCards = Set(ControlCenterCardType.allCases.map { $0.rawValue })
            expandedCards.insert("about")  // About card also expanded by default
            saveExpandedCards()
        }
    }

    /// Save expanded cards to UserDefaults
    private func saveExpandedCards() {
        if let encoded = try? JSONEncoder().encode(expandedCards) {
            userDefaults.set(encoded, forKey: expandedCardsKey)
        }
    }

    /// Load card order from UserDefaults
    private func loadCardOrder() {
        if let data = userDefaults.data(forKey: cardOrderKey),
           let decoded = try? JSONDecoder().decode([ControlCenterCardType].self, from: data) {
            var migratedOrder = decoded
            var needsMigration = false

            // Migration: Add .history card if it's missing from saved order
            if !migratedOrder.contains(.history) {
                // Insert History before Experience (matches default order)
                if let experienceIndex = migratedOrder.firstIndex(of: .experience) {
                    migratedOrder.insert(.history, at: experienceIndex)
                } else {
                    // Fallback: append to end if Experience not found
                    migratedOrder.append(.history)
                }
                needsMigration = true
            }

            // Migration: Add .experience card if it's missing from saved order
            if !migratedOrder.contains(.experience) {
                // Append Experience card to end of existing order
                migratedOrder.append(.experience)
                needsMigration = true
            }

            if !migratedOrder.contains(.dataManagement) {
                if let experienceIndex = migratedOrder.firstIndex(of: .experience) {
                    migratedOrder.insert(.dataManagement, at: experienceIndex)
                } else {
                    migratedOrder.append(.dataManagement)
                }
                needsMigration = true
            }

            cardOrder = migratedOrder

            // Save the migrated order if changes were made
            if needsMigration {
                saveCardOrder()
            }
        } else {
            // Default order: Goals → Notifications → Insights → Sync → History → Data Management → Experience
            cardOrder = [.goals, .notifications, .insights, .sync, .history, .dataManagement, .experience]
        }
    }

    /// Save card order to UserDefaults
    func saveCardOrder() {
        if let encoded = try? JSONEncoder().encode(cardOrder) {
            userDefaults.set(encoded, forKey: cardOrderKey)
        }
    }
}
