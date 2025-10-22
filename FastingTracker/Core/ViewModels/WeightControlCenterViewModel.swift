import SwiftUI
import Combine
import UserNotifications

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

    // MARK: - Phase 2a: Weight Tracker Notifications

    /// Timing mode for weight reminders
    enum TimingMode: String, Codable, CaseIterable {
        case specificTime = "Specific Time"
        case beforeFastingGoal = "Before Fasting Goal"
        case afterWakingUp = "After Waking Up"
    }

    /// Notification frequency options for user-configurable scheduling
    enum NotificationFrequency: String, Codable, CaseIterable {
        case daily = "Daily"
        case everyOtherDay = "Every Other Day"
        case twiceWeek = "Twice a Week"
        case weekly = "Weekly"
    }

    @Published var weightRemindersEnabled: Bool = false
    @Published var timingMode: TimingMode = .specificTime
    @Published var minutesOffset: Int = 30 // For beforeFastingGoal / afterWakingUp modes
    @Published var preferredReminderTime: Date = Date()
    @Published var quietHoursEnabled: Bool = false
    @Published var quietHoursStart: Date = Date()
    @Published var quietHoursEnd: Date = Date()
    @Published var skipWeekdays: Set<Int> = []

    // New notification types (Phase 2a enhancement - variable messaging)
    @Published var didYouKnowEnabled: Bool = false
    @Published var didYouKnowFrequency: NotificationFrequency = .daily
    @Published var motivationalEnabled: Bool = false
    @Published var motivationalFrequency: NotificationFrequency = .daily
    @Published var actionStepsEnabled: Bool = false
    @Published var actionStepsFrequency: NotificationFrequency = .daily

    // Weekday display data for UI
    let weekdays: [(number: Int, name: String)] = [
        (1, "Sunday"),
        (2, "Monday"),
        (3, "Tuesday"),
        (4, "Wednesday"),
        (5, "Thursday"),
        (6, "Friday"),
        (7, "Saturday")
    ]

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

    // Phase 2a: Weight notification keys (reuse WeightNotificationManager keys for consistency)
    private let weightRemindersEnabledKey = "weightRemindersEnabled"
    private let timingModeKey = "weightReminderTimingMode"
    private let minutesOffsetKey = "weightReminderMinutesOffset"
    private let weightReminderTimeKey = "weightReminderTime"
    private let quietHoursEnabledKey = "quietHoursEnabled"
    private let quietHoursStartKey = "quietHoursStart"
    private let quietHoursEndKey = "quietHoursEnd"
    private let skipWeekdaysKey = "skipWeekdays"

    // New notification type keys (Phase 2a enhancement - variable messaging)
    private let didYouKnowEnabledKey = "didYouKnowEnabled"
    private let didYouKnowFrequencyKey = "didYouKnowFrequency"
    private let motivationalEnabledKey = "motivationalEnabled"
    private let motivationalFrequencyKey = "motivationalFrequency"
    private let actionStepsEnabledKey = "actionStepsEnabled"
    private let actionStepsFrequencyKey = "actionStepsFrequency"

    // MARK: - Initialization

    init(weightManager: WeightManager, behavioralScheduler: BehavioralNotificationScheduler) {
        self.weightManager = weightManager
        self.behavioralScheduler = behavioralScheduler

        // Load persisted state
        loadCardOrder()
        loadExpandedCards()
        loadOptedOutContent()
        loadExperienceOptOuts()
        loadWeightNotificationSettings()
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
                Task<Void, Never> { @MainActor in
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
            Task<Void, Never> { @MainActor in
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
            Task<Void, Never> { @MainActor in
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
        Task<Void, Never> {
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
        Task<Void, Never> {
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

    // MARK: - Phase 2a: Weight Notification Settings

    /// Load weight notification settings from UserDefaults
    private func loadWeightNotificationSettings() {
        // Load enabled state
        weightRemindersEnabled = userDefaults.bool(forKey: weightRemindersEnabledKey)

        // Load timing mode (default: specificTime)
        if let modeString = userDefaults.string(forKey: timingModeKey),
           let mode = TimingMode(rawValue: modeString) {
            timingMode = mode
        } else {
            timingMode = .specificTime
        }

        // Load minutes offset (default: 30)
        let savedOffset = userDefaults.integer(forKey: minutesOffsetKey)
        minutesOffset = savedOffset > 0 ? savedOffset : 30

        // Load preferred time (default: 7:30 AM)
        if let timeData = userDefaults.data(forKey: weightReminderTimeKey),
           let components = try? JSONDecoder().decode(DateComponents.self, from: timeData),
           let hour = components.hour,
           let minute = components.minute {
            let calendar = Calendar.current
            var dateComponents = DateComponents()
            dateComponents.hour = hour
            dateComponents.minute = minute
            if let date = calendar.date(from: dateComponents) {
                preferredReminderTime = date
            } else {
                preferredReminderTime = makeDefaultTime(hour: 7, minute: 30)
            }
        } else {
            preferredReminderTime = makeDefaultTime(hour: 7, minute: 30)
        }

        // Load quiet hours
        quietHoursEnabled = userDefaults.bool(forKey: quietHoursEnabledKey)

        if let startData = userDefaults.data(forKey: quietHoursStartKey),
           let startComponents = try? JSONDecoder().decode(DateComponents.self, from: startData),
           let hour = startComponents.hour,
           let minute = startComponents.minute {
            quietHoursStart = makeDefaultTime(hour: hour, minute: minute)
        } else {
            quietHoursStart = makeDefaultTime(hour: 21, minute: 0) // Default: 9 PM
        }

        if let endData = userDefaults.data(forKey: quietHoursEndKey),
           let endComponents = try? JSONDecoder().decode(DateComponents.self, from: endData),
           let hour = endComponents.hour,
           let minute = endComponents.minute {
            quietHoursEnd = makeDefaultTime(hour: hour, minute: minute)
        } else {
            quietHoursEnd = makeDefaultTime(hour: 6, minute: 30) // Default: 6:30 AM
        }

        // Load skip weekdays
        if let array = userDefaults.array(forKey: skipWeekdaysKey) as? [Int] {
            skipWeekdays = Set(array)
        } else {
            skipWeekdays = []
        }

        // Load new notification types (Phase 2a enhancement)
        didYouKnowEnabled = userDefaults.bool(forKey: didYouKnowEnabledKey)
        if let frequencyString = userDefaults.string(forKey: didYouKnowFrequencyKey),
           let frequency = NotificationFrequency(rawValue: frequencyString) {
            didYouKnowFrequency = frequency
        } else {
            didYouKnowFrequency = .daily
        }

        motivationalEnabled = userDefaults.bool(forKey: motivationalEnabledKey)
        if let frequencyString = userDefaults.string(forKey: motivationalFrequencyKey),
           let frequency = NotificationFrequency(rawValue: frequencyString) {
            motivationalFrequency = frequency
        } else {
            motivationalFrequency = .daily
        }

        actionStepsEnabled = userDefaults.bool(forKey: actionStepsEnabledKey)
        if let frequencyString = userDefaults.string(forKey: actionStepsFrequencyKey),
           let frequency = NotificationFrequency(rawValue: frequencyString) {
            actionStepsFrequency = frequency
        } else {
            actionStepsFrequency = .daily
        }
    }

    /// Helper to create a Date from hour/minute for DatePicker binding
    private func makeDefaultTime(hour: Int, minute: Int) -> Date {
        let calendar = Calendar.current
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        return calendar.date(from: components) ?? Date()
    }

    /// Handle reminder toggle (enable/disable)
    func handleReminderToggle(_ enabled: Bool) {
        userDefaults.set(enabled, forKey: weightRemindersEnabledKey)

        if enabled {
            // Request authorization and schedule
            WeightNotificationManager.shared.requestAuthorization { granted in
                Task<Void, Never> { @MainActor in
                    if granted {
                        self.scheduleNextReminder()
                        AppLogger.notifications.info("Weight reminders enabled")
                    } else {
                        // Authorization denied - reset toggle
                        self.weightRemindersEnabled = false
                        self.userDefaults.set(false, forKey: self.weightRemindersEnabledKey)
                        AppLogger.notifications.warning("User denied notification authorization")
                    }
                }
            }
        } else {
            // Disable - cancel all weight reminders
            Task<Void, Never> {
                await WeightNotificationManager.shared.cancelAllWeightReminders()
                AppLogger.notifications.info("Weight reminders disabled")
            }
        }
    }

    /// Save timing mode to UserDefaults and reschedule
    func saveTimingMode() {
        userDefaults.set(timingMode.rawValue, forKey: timingModeKey)

        if weightRemindersEnabled {
            scheduleNextReminder()
            AppLogger.notifications.debug("Timing mode updated to \(self.timingMode.rawValue)")
        }
    }

    /// Save minutes offset to UserDefaults and reschedule
    func saveMinutesOffset() {
        userDefaults.set(minutesOffset, forKey: minutesOffsetKey)

        if weightRemindersEnabled {
            scheduleNextReminder()
            AppLogger.notifications.debug("Minutes offset updated to \(self.minutesOffset)")
        }
    }

    /// Save preferred reminder time to UserDefaults and reschedule
    func savePreferredTime() {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: preferredReminderTime)

        if let timeData = try? JSONEncoder().encode(components) {
            userDefaults.set(timeData, forKey: weightReminderTimeKey)
        }

        if weightRemindersEnabled {
            scheduleNextReminder()
            AppLogger.notifications.debug("Preferred reminder time updated")
        }
    }

    /// Save quiet hours to UserDefaults and reschedule
    func saveQuietHours() {
        userDefaults.set(quietHoursEnabled, forKey: quietHoursEnabledKey)

        let calendar = Calendar.current

        let startComponents = calendar.dateComponents([.hour, .minute], from: quietHoursStart)
        if let startData = try? JSONEncoder().encode(startComponents) {
            userDefaults.set(startData, forKey: quietHoursStartKey)
        }

        let endComponents = calendar.dateComponents([.hour, .minute], from: quietHoursEnd)
        if let endData = try? JSONEncoder().encode(endComponents) {
            userDefaults.set(endData, forKey: quietHoursEndKey)
        }

        if weightRemindersEnabled {
            scheduleNextReminder()
            AppLogger.notifications.debug("Quiet hours updated")
        }
    }

    /// Save skip weekdays to UserDefaults and reschedule
    func saveSkipWeekdays() {
        let array = Array(skipWeekdays)
        userDefaults.set(array, forKey: skipWeekdaysKey)

        if weightRemindersEnabled {
            scheduleNextReminder()
            AppLogger.notifications.debug("Skip weekdays updated")
        }
    }

    // MARK: - New Notification Types Save Methods (Phase 2a enhancement)

    /// Save Did You Know notification settings
    func saveDidYouKnowSettings() {
        userDefaults.set(didYouKnowEnabled, forKey: didYouKnowEnabledKey)
        userDefaults.set(didYouKnowFrequency.rawValue, forKey: didYouKnowFrequencyKey)

        // TODO: Reschedule Did You Know notifications when WeightNotificationManager supports them
        AppLogger.notifications.debug("Did You Know settings updated: enabled=\(self.didYouKnowEnabled), frequency=\(self.didYouKnowFrequency.rawValue)")
    }

    /// Save Motivational notification settings
    func saveMotivationalSettings() {
        userDefaults.set(motivationalEnabled, forKey: motivationalEnabledKey)
        userDefaults.set(motivationalFrequency.rawValue, forKey: motivationalFrequencyKey)

        // TODO: Reschedule Motivational notifications when WeightNotificationManager supports them
        AppLogger.notifications.debug("Motivational settings updated: enabled=\(self.motivationalEnabled), frequency=\(self.motivationalFrequency.rawValue)")
    }

    /// Save Action Steps notification settings
    func saveActionStepsSettings() {
        userDefaults.set(actionStepsEnabled, forKey: actionStepsEnabledKey)
        userDefaults.set(actionStepsFrequency.rawValue, forKey: actionStepsFrequencyKey)

        // TODO: Reschedule Action Steps notifications when WeightNotificationManager supports them
        AppLogger.notifications.debug("Action Steps settings updated: enabled=\(self.actionStepsEnabled), frequency=\(self.actionStepsFrequency.rawValue)")
    }

    /// Schedule next weight reminder using current settings
    private func scheduleNextReminder() {
        Task<Void, Never> {
            let calendar = Calendar.current
            let preferredComponents = calendar.dateComponents([.hour, .minute], from: preferredReminderTime)

            // Build quiet hours if enabled (supports midnight-spanning)
            var quietHours: WeightQuietHours?
            if quietHoursEnabled {
                let start = calendar.dateComponents([.hour, .minute], from: quietHoursStart)
                let end = calendar.dateComponents([.hour, .minute], from: quietHoursEnd)
                quietHours = WeightQuietHours(start: start, end: end)
            }

            do {
                try await WeightNotificationManager.shared.scheduleNextReminder(
                    preferredTime: preferredComponents,
                    quietHours: quietHours,
                    skipWeekdays: skipWeekdays
                )
                AppLogger.notifications.info("Next weight reminder scheduled successfully")

                // Debug: Print notification status
                await debugPendingNotifications()
            } catch {
                AppLogger.notifications.error("Failed to schedule weight reminder: \(error.localizedDescription)")
            }
        }
    }

    /// Debug helper: Print pending notifications to help troubleshoot
    func debugPendingNotifications() async {
        await WeightNotificationManager.shared.debugPrintPendingWeightReminders()
    }
}
