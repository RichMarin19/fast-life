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
    let goalCoordinator: WeightGoalCoordinator
    let notificationCoordinator: WeightNotificationCoordinator
    let measurementObserver: MeasurementSystemObserver
    private let syncCoordinator: WeightSyncCoordinating

    // Singleton managers (pass-through)
    let optOutManager: ContentOptOutManaging
    let cardManager: CardManager<TrackerCardType>
    let progressStoryCardManager: ProgressStoryCardManaging
    let healthKitManager: HealthKitManagerProtocol
    private var cancellables = Set<AnyCancellable>()
    private static let csvDateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
    private static let displayDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    // MARK: - Published State (was @State in View)

    // Card Management
    @Published var cardOrder: [ControlCenterCardType] = [.goals, .notifications, .insights, .sync, .history, .dataManagement, .experience]
    @Published var draggedCard: ControlCenterCardType?
    @Published var expandedCards: Set<String> = []

    // Badge/Interaction
    @Published var currentHighlightedItemIndex: Int = 0
    @Published var highlightedItemID: String?
    @Published var scrollViewProxy: ScrollViewProxy?
    @Published var badgeScale: CGFloat = 1.0

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

    // Data Management
    @Published var isExportingData: Bool = false
    @Published var isImportingData: Bool = false
    @Published var lastExportStatus: String?
    @Published var lastImportStatus: String?
    @Published var lastDeleteStatus: String?

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

    // MARK: - Private Properties (was @AppStorage in View)

    private let userDefaults: UserDefaults
    private var syncStatusCancellable: AnyCancellable?
    private var pendingInitialImport = false
    private var awaitingUserInitiatedSyncResult = false
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

    init(weightManager: WeightManager,
         behavioralScheduler: BehavioralNotificationScheduler,
         locale: Locale = .current,
         measurementProvider: MeasurementSystemProviding,
         measurementObserver: MeasurementSystemObserver,
         notificationCoordinator: WeightNotificationCoordinator,
         optOutManager: ContentOptOutManaging,
         cardManager: CardManager<TrackerCardType>,
         progressStoryCardManager: ProgressStoryCardManaging,
         healthKitManager: HealthKitManagerProtocol,
         syncCoordinator: WeightSyncCoordinating,
         userDefaults: UserDefaults) {
        self.weightManager = weightManager
        self.behavioralScheduler = behavioralScheduler
        self.optOutManager = optOutManager
        self.cardManager = cardManager
        self.progressStoryCardManager = progressStoryCardManager
        self.healthKitManager = healthKitManager
        self.userDefaults = userDefaults
        self.measurementObserver = measurementObserver
        self.goalCoordinator = WeightGoalCoordinator(
            weightManager: weightManager,
            measurementProvider: measurementProvider,
            locale: locale,
            healthKitManager: healthKitManager
        )
        self.notificationCoordinator = notificationCoordinator
        self.syncCoordinator = syncCoordinator
        
        // Load persisted state
        loadCardOrder()
        loadExpandedCards()
        loadOptedOutContent()
        loadExperienceOptOuts()

        goalCoordinator.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)

        self.notificationCoordinator.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)

        self.cardManager.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)

        self.progressStoryCardManager.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)

        syncStatusCancellable = syncCoordinator.statusPublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] status in
                self?.handleSyncStatus(status)
            }
    }

    deinit {
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

    var areAllProgressStoryCardsVisible: Bool {
        let cardsVisible = ProgressStoryCardType.allCases.allSatisfy { progressStoryCardManager.isCardVisible($0) }
        let anyOptedOut = ProgressStoryCardType.allCases.contains { cardType in
            guard let contentID = cardType.optOutContentID else { return false }
            return optOutManager.isContentOptedOut(id: contentID)
        }
        return cardsVisible && !anyOptedOut
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

    // MARK: - Start Weight Management

    var unitAbbreviation: String {
        goalCoordinator.unitAbbreviation
    }

    var startWeightString: String {
        get { goalCoordinator.startWeightString }
        set { goalCoordinator.startWeightString = newValue }
    }

    var startWeightDate: Date {
        get { goalCoordinator.startWeightDate }
        set { goalCoordinator.startWeightDate = newValue }
    }

    var isFetchingStartWeight: Bool {
        goalCoordinator.isFetchingStartWeight
    }

    var startWeightStatusMessage: String? {
        goalCoordinator.startWeightStatusMessage
    }

    var startWeightErrorMessage: String? {
        goalCoordinator.startWeightErrorMessage
    }

    var milestoneCount: Int {
        get { goalCoordinator.milestoneCount }
        set { goalCoordinator.milestoneCount = newValue }
    }

    var weightGoalString: String {
        get { goalCoordinator.weightGoalString }
        set { goalCoordinator.weightGoalString = newValue }
    }

    var canSaveStartWeight: Bool {
        goalCoordinator.canSaveStartWeight
    }

    func prepareStartWeightDefaults() {
        goalCoordinator.prepareStartWeightDefaults()
    }

    func handleStartWeightDateChange(_ date: Date) {
        goalCoordinator.handleStartWeightDateChange(date)
    }

    func formatStartWeightInput(_ input: String) {
        goalCoordinator.formatStartWeightInput(input)
    }

    func fetchStartWeight(for date: Date) {
        goalCoordinator.fetchStartWeight(for: date)
    }

    func saveStartWeight() {
        goalCoordinator.saveStartWeight()
    }

    func formatWeightGoalInput(_ input: String) {
        goalCoordinator.formatWeightGoalInput(input)
    }

    func updateMilestoneCount(_ newValue: Int) {
        goalCoordinator.updateMilestoneCount(newValue)
    }
    // MARK: - HealthKit Sync Methods

    func syncWithHealthKit() {
        isSyncing = true

        let isAuthorized = healthKitManager.isWeightAuthorized()

        if !isAuthorized {
            healthKitManager.requestWeightAuthorization { success, error in
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
        hasHealthKitPermission = healthKitManager.isWeightAuthorized()
        let authStatus = healthKitManager.getWeightAuthorizationStatus()

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
        if let lastSyncDate = healthKitManager.lastWeightSyncDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .none
            formatter.timeStyle = .short

            let timeString = formatter.string(from: lastSyncDate)

            if healthKitManager.lastWeightSyncError != nil {
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
        awaitingUserInitiatedSyncResult = true
        guard !weightManager.weightEntries.isEmpty else {
            performHistoricalSync()
            return
        }

        pendingInitialImport = false
        syncCoordinator.sync(initialImport: false)
    }

    func performHistoricalSync() {
        awaitingUserInitiatedSyncResult = true
        if hasHealthKitPermission {
            weightManager.resetFutureOnlySyncCutoff()
            weightManager.setSyncPreference(true)
            userSyncPreference = true
        }
        pendingInitialImport = true
        syncCoordinator.sync(initialImport: true)
    }

    func performFutureOnlySync() {
        markInitialImportCompleted()

        syncMessage = "Weight sync enabled. Only new weight entries will be synced going forward."
        showingSyncAlert = true

        if hasHealthKitPermission {
            weightManager.enableFutureOnlySync()
            userSyncPreference = true
            updatePermissionStatus()
            loadLastSyncStatus()
            updateToggleState()
        }
    }

    // MARK: - Data Management

    @MainActor
    func exportWeightData() async throws -> URL {
        let entries = weightManager.weightEntries.sorted { $0.date < $1.date }
        guard !entries.isEmpty else { throw DataManagementError.noEntries }

        isExportingData = true
        defer { isExportingData = false }

        var csv = "Date,Weight (lbs),BMI,BodyFat,Source\n"
        for entry in entries {
            let row = csvRow([
                Self.csvDateFormatter.string(from: entry.date),
                String(format: "%.4f", entry.weight),
                entry.bmi.map { String(format: "%.4f", $0) } ?? "",
                entry.bodyFat.map { String(format: "%.2f", $0) } ?? "",
                entry.source.rawValue
            ])
            csv.append(row + "\n")
        }

        let timestamp = Self.csvDateFormatter.string(from: Date())
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("WeightData-\(timestamp).csv")
        try csv.write(to: url, atomically: true, encoding: .utf8)

        lastExportStatus = "Exported \(entries.count) entries · \(Self.displayDateFormatter.string(from: Date()))"
        return url
    }

    @MainActor
    func importWeightData(from url: URL) async throws -> WeightDataImportSummary {
        isImportingData = true
        defer { isImportingData = false }

        guard url.startAccessingSecurityScopedResource() else {
            throw DataManagementError.unreadableFile
        }
        defer { url.stopAccessingSecurityScopedResource() }

        let content = try String(contentsOf: url, encoding: .utf8)
        let rows = content.split(whereSeparator: \.isNewline)
        guard rows.count > 1 else { throw DataManagementError.invalidFormat }

        var existingKeys = Set(weightManager.weightEntries.map { Self.csvDateFormatter.string(from: $0.date) })
        var imported = 0
        var skipped = 0

        for row in rows.dropFirst() {
            let fields = parseCSVRow(String(row))
            guard fields.count >= 2,
                  let date = Self.csvDateFormatter.date(from: fields[0]),
                  let weight = Double(fields[1]) else {
                continue
            }

            let key = Self.csvDateFormatter.string(from: date)
            if existingKeys.contains(key) {
                skipped += 1
                continue
            }

            let bmi = Double(fields[safe: 2] ?? "")
            let bodyFat = Double(fields[safe: 3] ?? "")
            let entry = WeightEntry(
                date: date,
                weight: weight,
                bmi: bmi,
                bodyFat: bodyFat,
                source: .manual
            )

            weightManager.addWeightEntry(entry)
            existingKeys.insert(key)
            imported += 1
        }

        guard imported > 0 else {
            throw imported == 0 && skipped > 0 ? DataManagementError.onlyDuplicates : DataManagementError.invalidFormat
        }

        lastImportStatus = "Imported \(imported) (\(skipped) skipped) · \(Self.displayDateFormatter.string(from: Date()))"
        return WeightDataImportSummary(imported: imported, skipped: skipped)
    }

    @MainActor
    func deleteAllWeightData() {
        let total = weightManager.weightEntries.count
        weightManager.deleteAllWeightData()
        lastDeleteStatus = "Deleted \(total) entries · \(Self.displayDateFormatter.string(from: Date()))"
    }

    enum DataManagementError: LocalizedError {
        case noEntries
        case unreadableFile
        case invalidFormat
        case onlyDuplicates

        var errorDescription: String? {
            switch self {
            case .noEntries:
                return "No weight entries are available to export."
            case .unreadableFile:
                return "Cannot read the selected file."
            case .invalidFormat:
                return "The file is not a valid Fast LIFe weight export."
            case .onlyDuplicates:
                return "All entries in the file already exist."
            }
        }
    }

    private func csvRow(_ values: [String]) -> String {
        values.map { "\"\($0)\"" }.joined(separator: ",")
    }

    private func parseCSVRow(_ row: String) -> [String] {
        row.split(separator: ",", omittingEmptySubsequences: false)
            .map { $0.trimmingCharacters(in: CharacterSet(charactersIn: "\"")) }
    }

    func hasCompletedInitialImport() -> Bool {
        return userDefaults.bool(forKey: hasCompletedInitialImportKey)
    }

    func markInitialImportCompleted() {
        userDefaults.set(true, forKey: hasCompletedInitialImportKey)
        userDefaults.synchronize()
    }

    private func handleSyncStatus(_ status: WeightSyncStatus) {
        switch status {
        case .idle:
            isSyncing = false
        case .syncing:
            isSyncing = true
        case .success(let newEntries):
            isSyncing = false
            syncMessage = "Successfully synced \(newEntries) weight entries from Apple Health."
            if awaitingUserInitiatedSyncResult {
                showingSyncAlert = true
            }
            completeSyncIfNeeded()
            awaitingUserInitiatedSyncResult = false
        case .upToDate:
            isSyncing = false
            syncMessage = "Weight data is up to date. No new entries found in Apple Health."
            if awaitingUserInitiatedSyncResult {
                showingSyncAlert = true
            }
            completeSyncIfNeeded()
            awaitingUserInitiatedSyncResult = false
        case .failure(let message):
            isSyncing = false
            syncMessage = message
            if awaitingUserInitiatedSyncResult {
                showingSyncAlert = true
            }
            awaitingUserInitiatedSyncResult = false
        }
    }

    private func completeSyncIfNeeded() {
        if pendingInitialImport {
            markInitialImportCompleted()
            pendingInitialImport = false
        }
        updatePermissionStatus()
        loadLastSyncStatus()
        updateToggleState()
    }

    // MARK: - Badge Interaction: Cycle Through Opted-Out Items

    /// Cycle to next opted-out item when badge is tapped
    /// Industry pattern: Instagram stories badge, Spotify playlist scroll
    func cycleToNextOptedOutItem() {
        // Get all opted-out items in visual top-to-bottom order
        let allOptedOutItems = visuallyOrderedOptedOutItems

        guard !allOptedOutItems.isEmpty else { return }

        // Get the target item to scroll to (use CURRENT index before incrementing)
        let targetItem = allOptedOutItems[currentHighlightedItemIndex]

        // Increment index BEFORE UI operations (so tests can verify immediately)
        currentHighlightedItemIndex = (currentHighlightedItemIndex + 1) % allOptedOutItems.count

        // Layer 3: Smooth scroll to target item with animation (only if proxy exists)
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

        triggerBadgeBounce()
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
        triggerBadgeBounce()
    }

    func restoreProgressStoryCard(_ cardType: ProgressStoryCardType) {
        progressStoryCardManager.showCard(cardType)

        if let contentID = cardType.optOutContentID {
            optOutManager.optInContent(id: contentID)
            optedOutContentItems.removeAll { $0.id == contentID }
            saveOptedOutContent()
        }

        triggerBadgeBounce()
    }

    func setProgressStoryExperienceVisible(_ isVisible: Bool) {
        ProgressStoryCardType.allCases.forEach { cardType in
            if isVisible {
                progressStoryCardManager.showCard(cardType)
                if let contentID = cardType.optOutContentID {
                    optOutManager.optInContent(id: contentID)
                }
            } else {
                progressStoryCardManager.hideCard(cardType)
                if let contentID = cardType.optOutContentID {
                    optOutManager.optOutContent(id: contentID, category: .progressSummaries, text: cardType.displayName)
                }
            }
        }

        optOutProgressSummaries = !isVisible
        saveExperienceOptOuts()
        optedOutContentItems = optOutManager.optedOutContentItems
    }

    func restoreTrackerCard(_ cardType: TrackerCardType) {
        cardManager.showCard(cardType)
        saveExperienceOptOuts()
    }

    private func triggerBadgeBounce() {
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
    }

}

// MARK: - Factories

extension WeightControlCenterViewModel {

    struct Dependencies {
        let measurementProvider: MeasurementSystemProviding
        let measurementObserver: MeasurementSystemObserver
        let healthKitManager: HealthKitManagerProtocol
        let notificationCoordinator: WeightNotificationCoordinator
        let optOutManager: ContentOptOutManaging
        let trackerCardManager: CardManager<TrackerCardType>
        let progressStoryCardManager: ProgressStoryCardManaging
        let syncCoordinator: WeightSyncCoordinating
        let userDefaults: UserDefaults
    }

    @MainActor
    static func live(
        weightManager: WeightManager,
        behavioralScheduler: BehavioralNotificationScheduler,
        locale: Locale = .current,
        dependencies: Dependencies
    ) -> WeightControlCenterViewModel {
        WeightControlCenterViewModel(
            weightManager: weightManager,
            behavioralScheduler: behavioralScheduler,
            locale: locale,
            measurementProvider: dependencies.measurementProvider,
            measurementObserver: dependencies.measurementObserver,
            notificationCoordinator: dependencies.notificationCoordinator,
            optOutManager: dependencies.optOutManager,
            cardManager: dependencies.trackerCardManager,
            progressStoryCardManager: dependencies.progressStoryCardManager,
            healthKitManager: dependencies.healthKitManager,
            syncCoordinator: dependencies.syncCoordinator,
            userDefaults: dependencies.userDefaults
        )
    }

    @MainActor
    static func preview() -> WeightControlCenterViewModel {
        let deps = WeightDependencies.preview()
        let suiteName = "WeightControlCenterViewModel.preview"
        let userDefaults = UserDefaults(suiteName: suiteName) ?? .standard
        userDefaults.removePersistentDomain(forName: suiteName)
        return deps.makeControlCenterViewModel(userDefaults: userDefaults)
    }
}

struct WeightDataImportSummary {
    let imported: Int
    let skipped: Int
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        guard indices.contains(index) else { return nil }
        return self[index]
    }
}
