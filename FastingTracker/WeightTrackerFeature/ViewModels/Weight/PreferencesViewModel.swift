import SwiftUI
import UIKit

/// ViewModel for Weight Control Center Preferences
/// Handles experience opt-outs, content opt-outs, and restore functionality
/// Extracted from WeightControlCenterViewModel as part of Phase 8.9 Phase 2
/// Reference: HANDOFF.md - Weight Tracker Refactoring
@MainActor
class PreferencesViewModel: ObservableObject {
    // MARK: - Published State

    // Experience Opt-Out Toggles
    @Published var optOutTrackerCards: Bool = false
    @Published var optOutEducationalInsights: Bool = false
    @Published var optOutBehavioralNudges: Bool = false
    @Published var optOutMotivationalMessages: Bool = false
    @Published var optOutProgressSummaries: Bool = false

    // Content Opt-Out Items
    @Published var optedOutContentItems: [ContentItem] = []

    // Alerts
    @Published var showingRestoreAllAlert = false

    // MARK: - Dependencies

    let optOutManager: ContentOptOutManaging
    let cardManager: TrackerCardManaging
    let progressStoryCardManager: ProgressStoryCardManaging

    // MARK: - Private Properties

    private let userDefaults: UserDefaults
    private let optedOutContentKey = "optedOutContentItems"

    // Experience opt-out keys
    private let optOutTrackerCardsKey = "experienceOptOut_trackerCards"
    private let optOutEducationalInsightsKey = "experienceOptOut_educationalInsights"
    private let optOutBehavioralNudgesKey = "experienceOptOut_behavioralNudges"
    private let optOutMotivationalMessagesKey = "experienceOptOut_motivationalMessages"
    private let optOutProgressSummariesKey = "experienceOptOut_progressSummaries"

    // MARK: - Initialization

    init(optOutManager: ContentOptOutManaging,
         cardManager: TrackerCardManaging,
         progressStoryCardManager: ProgressStoryCardManaging,
         userDefaults: UserDefaults = .standard) {
        self.optOutManager = optOutManager
        self.cardManager = cardManager
        self.progressStoryCardManager = progressStoryCardManager
        self.userDefaults = userDefaults
        loadOptedOutContent()
        loadExperienceOptOuts()
    }

    // MARK: - Computed Properties

    /// Determines if the "Restore All" button should be visible
    var shouldShowRestoreButton: Bool {
        let hasCategoryOptOuts = optOutTrackerCards ||
            optOutEducationalInsights ||
            optOutBehavioralNudges ||
            optOutMotivationalMessages ||
            optOutProgressSummaries

        let hasIndividualOptOuts = !optOutManager.optedOutContentItems.isEmpty

        let hasHiddenTrackerCards = TrackerCardType.allCases.contains { cardType in
            !cardManager.isCardVisible(cardType)
        }

        let hasHiddenProgressStoryCards = ProgressStoryCardType.allCases.contains { cardType in
            !progressStoryCardManager.isCardVisible(cardType)
        }

        return hasCategoryOptOuts || hasIndividualOptOuts || hasHiddenTrackerCards || hasHiddenProgressStoryCards
    }

    /// Returns opted-out items ordered by category (for consistent UI display)
    var visuallyOrderedOptedOutItems: [ContentItem] {
        let categoryOrder: [ContentCategory] = [
            .educationalInsights,
            .behavioralNudges,
            .motivationalMessages,
            .progressSummaries
        ]

        var orderedItems: [ContentItem] = []
        for category in categoryOrder {
            let itemsInCategory = optOutManager.optedOutContentItems.filter { $0.category == category }
            orderedItems.append(contentsOf: itemsInCategory)
        }

        return orderedItems
    }

    // MARK: - Content Opt-Out Methods

    /// Opt out of specific content item
    func optOutContent(id: String, category: ContentCategory, text: String) {
        let newItem = ContentItem(id: id, category: category, displayText: text)

        // Check if already opted out
        if !optedOutContentItems.contains(where: { $0.id == id }) {
            optedOutContentItems.append(newItem)
            saveOptedOutContent()
        }
    }

    /// Opt back in to specific content item
    func optInContent(id: String) {
        optedOutContentItems.removeAll { $0.id == id }
        saveOptedOutContent()
    }

    /// Check if specific content is opted out
    func isContentOptedOut(id: String) -> Bool {
        return optedOutContentItems.contains(where: { $0.id == id })
    }

    // MARK: - Restore All Functionality

    /// Restore all content to default state
    /// Restores: Hidden tracker cards, hidden Progress Story cards, category opt-outs, individual opt-outs
    func restoreAllToDefault() {
        // 1. Restore all tracker cards (show all) via TrackerCardManager
        for cardType in TrackerCardType.allCases {
            cardManager.showCard(cardType)
        }

        // 2. Restore all Progress Story cards (show all) via ProgressStoryCardManager
        for cardType in ProgressStoryCardType.allCases {
            progressStoryCardManager.showCard(cardType)
        }

        // 3. Restore all category opt-outs (turn all ON)
        optOutTrackerCards = false
        optOutEducationalInsights = false
        optOutBehavioralNudges = false
        optOutMotivationalMessages = false
        optOutProgressSummaries = false
        saveExperienceOptOuts()

        // 4. Clear all individual opt-outs
        optOutManager.optedOutContentItems.removeAll()
        optedOutContentItems.removeAll()
        saveOptedOutContent()

        // Haptic feedback for confirmation
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    // MARK: - Persistence

    /// Load opted-out content items from UserDefaults
    private func loadOptedOutContent() {
        if let data = userDefaults.data(forKey: optedOutContentKey),
           let decoded = try? JSONDecoder().decode([ContentItem].self, from: data) {
            optedOutContentItems = decoded
        }
    }

    /// Save opted-out content items to UserDefaults
    private func saveOptedOutContent() {
        if let encoded = try? JSONEncoder().encode(optedOutContentItems) {
            userDefaults.set(encoded, forKey: optedOutContentKey)
        }
    }

    /// Load experience opt-out preferences from UserDefaults
    private func loadExperienceOptOuts() {
        optOutTrackerCards = userDefaults.bool(forKey: optOutTrackerCardsKey)
        optOutEducationalInsights = userDefaults.bool(forKey: optOutEducationalInsightsKey)
        optOutBehavioralNudges = userDefaults.bool(forKey: optOutBehavioralNudgesKey)
        optOutMotivationalMessages = userDefaults.bool(forKey: optOutMotivationalMessagesKey)
        optOutProgressSummaries = userDefaults.bool(forKey: optOutProgressSummariesKey)
    }

    /// Save experience opt-out preferences to UserDefaults
    func saveExperienceOptOuts() {
        userDefaults.set(optOutTrackerCards, forKey: optOutTrackerCardsKey)
        userDefaults.set(optOutEducationalInsights, forKey: optOutEducationalInsightsKey)
        userDefaults.set(optOutBehavioralNudges, forKey: optOutBehavioralNudgesKey)
        userDefaults.set(optOutMotivationalMessages, forKey: optOutMotivationalMessagesKey)
        userDefaults.set(optOutProgressSummaries, forKey: optOutProgressSummariesKey)
        userDefaults.synchronize()
    }
}
