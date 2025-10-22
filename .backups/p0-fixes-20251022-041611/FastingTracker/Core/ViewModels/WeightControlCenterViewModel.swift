import SwiftUI
import Combine

/// ViewModel for Weight Control Center
/// Industry Pattern: MVVM (Apple WWDC 2023 recommendation)
/// Extracts state and business logic from WeightControlCenterView
/// Reference: PHASE-v1.7-VIEWMODEL-EXTRACTION-PLAN.md
@MainActor
class WeightControlCenterViewModel: ObservableObject {
    // MARK: - Dependencies (Injected)

    let weightManager: WeightManager
    let behavioralScheduler: BehavioralNotificationScheduler

    // Singleton managers (pass-through)
    let optOutManager = ContentOptOutManager.shared
    let cardManager = TrackerCards.shared
    let progressStoryCardManager = ProgressStoryCards.shared

    // MARK: - Published State (was @State in View)

    // Card Management
    @Published var cardOrder: [ControlCenterCardType] = [.goals, .notifications, .insights, .sync, .history, .experience]
    @Published var draggedCard: ControlCenterCardType?
    @Published var expandedCards: Set<String> = []

    // Badge/Interaction
    @Published var currentHighlightedItemIndex: Int = 0
    @Published var highlightedItemID: String?
    @Published var scrollViewProxy: ScrollViewProxy?
    @Published var badgeScale: CGFloat = 1.0

    // Goals
    @Published var weightGoalString: String = ""

    // Sync State
    @Published var localSyncEnabled: Bool = true
    @Published var userSyncPreference: Bool = true
    @Published var isSyncing: Bool = false
    @Published var showingSyncAlert: Bool = false
    @Published var syncMessage: String = ""
    @Published var hasHealthKitPermission: Bool = false
    @Published var permissionStatusMessage: String = ""
    @Published var canEnableSync: Bool = true
    @Published var lastSyncStatus: String = ""
    @Published var showingWeightSyncDetails: Bool = false
    @Published var showingSyncPreferenceDialog: Bool = false

    // Experience Opt-Out
    @Published var optOutTrackerCards: Bool = false
    @Published var optOutEducationalInsights: Bool = false
    @Published var optOutBehavioralNudges: Bool = false
    @Published var optOutMotivationalMessages: Bool = false
    @Published var optOutProgressSummaries: Bool = false

    // Content Opt-Out
    @Published var optedOutContentItems: [ContentItem] = []

    // Alerts
    @Published var showingRestoreAllAlert = false

    // MARK: - Private Properties (was @AppStorage in View)

    private let userDefaults = UserDefaults.standard
    private let hasCompletedInitialImportKey = "weightHasCompletedInitialImport"

    // AppStorage keys
    private let cardOrderKey = "weightControlCenterCardOrder"
    private let expandedCardsKey = "controlCenterExpandedCards"
    private let optedOutContentKey = "optedOutContentItems"

    // Experience opt-out keys
    private let optOutTrackerCardsKey = "experienceOptOut_trackerCards"
    private let optOutEducationalInsightsKey = "experienceOptOut_educationalInsights"
    private let optOutBehavioralNudgesKey = "experienceOptOut_behavioralNudges"
    private let optOutMotivationalMessagesKey = "experienceOptOut_motivationalMessages"
    private let optOutProgressSummariesKey = "experienceOptOut_progressSummaries"

    // MARK: - Initialization

    init(weightManager: WeightManager, behavioralScheduler: BehavioralNotificationScheduler) {
        self.weightManager = weightManager
        self.behavioralScheduler = behavioralScheduler

        // Load persisted state
        loadCardOrder()
        loadExpandedCards()
        loadOptedOutContent()
        loadExperienceOptOuts()
    }

    // MARK: - Computed Properties

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

    // MARK: - Card Management Methods

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

    /// Load expanded cards from UserDefaults
    func loadExpandedCards() {
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
    func saveExpandedCards() {
        if let encoded = try? JSONEncoder().encode(expandedCards) {
            userDefaults.set(encoded, forKey: expandedCardsKey)
        }
    }

    /// Load card order from UserDefaults
    func loadCardOrder() {
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

            cardOrder = migratedOrder

            // Save the migrated order if changes were made
            if needsMigration {
                saveCardOrder()
            }
        } else {
            // Default order: Goals → Notifications → Insights → Sync → History → Experience
            cardOrder = [.goals, .notifications, .insights, .sync, .history, .experience]
        }
    }

    /// Save card order to UserDefaults
    func saveCardOrder() {
        if let encoded = try? JSONEncoder().encode(cardOrder) {
            userDefaults.set(encoded, forKey: cardOrderKey)
        }
    }

    // MARK: - HealthKit Sync Methods

    func syncWithHealthKit() {
        isSyncing = true

        let isAuthorized = HealthKitManager.shared.isWeightAuthorized()

        if !isAuthorized {
            HealthKitManager.shared.requestWeightAuthorization { success, error in
                Task { @MainActor in
                    if success {
                        self.isSyncing = false
                        if self.hasCompletedInitialImport() {
                            self.performSync()
                        } else {
                            self.showingSyncPreferenceDialog = true
                        }
                    } else {
                        self.isSyncing = false
                        self.syncMessage = error?.localizedDescription ?? "HealthKit authorization required. Enable weight access in Settings."
                        self.showingSyncAlert = true
                    }
                }
            }
        } else {
            if hasCompletedInitialImport() {
                performSync()
            } else {
                isSyncing = false
                showingSyncPreferenceDialog = true
            }
        }
    }

    func updatePermissionStatus() {
        hasHealthKitPermission = HealthKitManager.shared.isWeightAuthorized()
        let authStatus = HealthKitManager.shared.getWeightAuthorizationStatus()

        canEnableSync = (authStatus != .sharingDenied)

        if hasHealthKitPermission {
            permissionStatusMessage = "When enabled, weight entries will sync automatically."
        } else {
            if authStatus == .notDetermined {
                permissionStatusMessage = "Tap 'Sync Now' to set up Apple Health integration."
            } else {
                permissionStatusMessage = "Permission denied. Enable in Settings → Privacy → Health."
            }
        }
    }

    func updateToggleState() {
        if hasHealthKitPermission {
            localSyncEnabled = userSyncPreference
        } else {
            localSyncEnabled = false
        }
    }

    func loadLastSyncStatus() {
        if let lastSyncDate = HealthKitManager.shared.lastWeightSyncDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .none
            formatter.timeStyle = .short

            let timeString = formatter.string(from: lastSyncDate)

            if HealthKitManager.shared.lastWeightSyncError != nil {
                lastSyncStatus = "Last sync failed at \(timeString)"
            } else {
                if Calendar.current.isDateInToday(lastSyncDate) {
                    lastSyncStatus = "Last synced today at \(timeString)"
                } else {
                    formatter.dateStyle = .short
                    lastSyncStatus = "Last synced \(formatter.string(from: lastSyncDate))"
                }
            }
        } else {
            lastSyncStatus = ""
        }
    }

    func performSync() {
        let startDate = Calendar.current.date(byAdding: .year, value: -10, to: Date()) ?? Date()

        weightManager.syncFromHealthKitWithReset(startDate: startDate) { syncedCount, error in
            Task { @MainActor in
                self.isSyncing = false

                if let error = error {
                    self.syncMessage = error.localizedDescription
                    self.showingSyncAlert = true
                } else {
                    if syncedCount > 0 {
                        self.syncMessage = "Successfully synced \(syncedCount) new weight entries from Apple Health."
                    } else {
                        let hasPermission = HealthKitManager.shared.isWeightAuthorized()
                        if hasPermission {
                            self.syncMessage = "Weight data is up to date. No new entries found in Apple Health."
                        } else {
                            self.syncMessage = "Permission denied. To enable weight sync, go to Settings → Privacy → Health."
                        }
                    }
                    self.showingSyncAlert = true

                    self.updatePermissionStatus()
                    self.loadLastSyncStatus()
                    self.updateToggleState()

                    if self.hasHealthKitPermission && self.userSyncPreference {
                        self.weightManager.setSyncPreference(true)
                    }
                }
            }
        }
    }

    func performHistoricalSync() {
        markInitialImportCompleted()
        isSyncing = true

        let startDate = Calendar.current.date(byAdding: .year, value: -10, to: Date()) ?? Date()

        weightManager.syncFromHealthKitHistorical(startDate: startDate) { syncedCount, error in
            Task { @MainActor in
                self.isSyncing = false

                if let error = error {
                    self.syncMessage = "Failed to import historical weight data: \(error.localizedDescription)"
                    self.showingSyncAlert = true
                } else {
                    if syncedCount > 0 {
                        self.syncMessage = "Successfully imported \(syncedCount) weight entries from your Apple Health history."
                    } else {
                        self.syncMessage = "All weight data is already up to date. No new historical entries found."
                    }
                    self.showingSyncAlert = true

                    if self.hasHealthKitPermission {
                        self.weightManager.setSyncPreference(true)
                        self.userSyncPreference = true
                        self.updatePermissionStatus()
                        self.loadLastSyncStatus()
                        self.updateToggleState()
                    }
                }
            }
        }
    }

    func performFutureOnlySync() {
        markInitialImportCompleted()

        syncMessage = "Weight sync enabled. Only new weight entries will be synced going forward."
        showingSyncAlert = true

        if hasHealthKitPermission {
            weightManager.setSyncPreference(true)
            userSyncPreference = true
            updatePermissionStatus()
            loadLastSyncStatus()
            updateToggleState()
        }
    }

    func hasCompletedInitialImport() -> Bool {
        return userDefaults.bool(forKey: hasCompletedInitialImportKey)
    }

    func markInitialImportCompleted() {
        userDefaults.set(true, forKey: hasCompletedInitialImportKey)
        userDefaults.synchronize()
    }

    // MARK: - Weight Goal Input Formatting

    /// Format weight goal input to one decimal place, max 999.9
    /// UX/UI Fix #2: Industry standard for health apps
    func formatWeightGoalInput(_ input: String) {
        var formatted = input

        // Remove any non-numeric characters except decimal point
        formatted = formatted.filter { $0.isNumber || $0 == "." }

        // Ensure only one decimal point
        let components = formatted.components(separatedBy: ".")
        if components.count > 2 {
            formatted = components[0] + "." + components[1...].joined()
        }

        // Limit to one decimal place
        if let dotIndex = formatted.firstIndex(of: ".") {
            let afterDot = formatted.suffix(from: formatted.index(after: dotIndex))
            if afterDot.count > 1 {
                formatted = String(formatted.prefix(upTo: formatted.index(dotIndex, offsetBy: 2)))
            }
        }

        // Enforce max value 999.9
        if let value = Double(formatted), value > 999.9 {
            formatted = "999.9"
        }

        // Limit integer part to 3 digits
        if let dotIndex = formatted.firstIndex(of: ".") {
            let beforeDot = formatted.prefix(upTo: dotIndex)
            if beforeDot.count > 3 {
                formatted = String(beforeDot.prefix(3)) + String(formatted.suffix(from: dotIndex))
            }
        } else {
            if formatted.count > 3 {
                formatted = String(formatted.prefix(3))
            }
        }

        // Update if changed
        if formatted != input {
            weightGoalString = formatted
        }
    }

    // MARK: - Badge Interaction: Cycle Through Opted-Out Items

    /// Cycle to next opted-out item when badge is tapped
    /// Industry pattern: Instagram stories badge, Spotify playlist scroll
    func cycleToNextOptedOutItem() {
        // Get all opted-out items in visual top-to-bottom order
        let allOptedOutItems = visuallyOrderedOptedOutItems

        guard !allOptedOutItems.isEmpty else { return }

        // Get the target item to scroll to (use CURRENT index, don't increment yet)
        let targetItem = allOptedOutItems[currentHighlightedItemIndex]

        // Layer 3: Smooth scroll to target item with animation
        guard let proxy = scrollViewProxy else { return }

        withAnimation(.easeInOut(duration: 0.35)) {
            proxy.scrollTo(targetItem.id, anchor: .center)
        }

        // Layer 4: Set highlighted item ID for gold border
        highlightedItemID = targetItem.id

        // Auto-reset highlight after 1 second
        Task {
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            await MainActor.run {
                withAnimation {
                    highlightedItemID = nil
                }
            }
        }

        // Layer 5: Haptic feedback - Light tap for premium feel
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        // Layer 6: Badge bounce animation (1.0 → 1.15 → 1.0)
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            badgeScale = 1.15
        }
        Task {
            try? await Task.sleep(nanoseconds: 150_000_000)
            await MainActor.run {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    badgeScale = 1.0
                }
            }
        }

        // Increment index for NEXT tap (after scrolling to current item)
        currentHighlightedItemIndex = (currentHighlightedItemIndex + 1) % allOptedOutItems.count
    }

    // MARK: - Opt-Out System Helper Functions

    /// Load opted-out content items from UserDefaults
    func loadOptedOutContent() {
        if let data = userDefaults.data(forKey: optedOutContentKey),
           let decoded = try? JSONDecoder().decode([ContentItem].self, from: data) {
            optedOutContentItems = decoded
        }
    }

    /// Save opted-out content items to UserDefaults
    func saveOptedOutContent() {
        if let encoded = try? JSONEncoder().encode(optedOutContentItems) {
            userDefaults.set(encoded, forKey: optedOutContentKey)
        }
    }

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
}
