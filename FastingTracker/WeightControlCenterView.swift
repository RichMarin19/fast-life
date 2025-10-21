import SwiftUI

// MARK: - Content Opt-Out System

/// Individual content item that can be opted out
/// Used for granular control over tips, nudges, messages, and summaries
struct ContentItem: Identifiable, Codable, Equatable {
    let id: String
    let category: ContentCategory
    let displayText: String
    var isOptedOut: Bool
    let timestamp: Date

    init(id: String, category: ContentCategory, displayText: String) {
        self.id = id
        self.category = category
        self.displayText = displayText
        self.isOptedOut = true  // Opted out by default when created
        self.timestamp = Date()
    }
}

/// Content categories for organization
enum ContentCategory: String, Codable, CaseIterable {
    case educationalInsights = "educational_insights"
    case behavioralNudges = "behavioral_nudges"
    case motivationalMessages = "motivational_messages"
    case progressSummaries = "progress_summaries"

    var displayName: String {
        switch self {
        case .educationalInsights: return "Educational Insights"
        case .behavioralNudges: return "Behavioral Nudges"
        case .motivationalMessages: return "Motivational Messages"
        case .progressSummaries: return "Your Progress Journey"
        }
    }
}

/// Weight Tracker card types that can be hidden/shown
/// Used in Control Center for managing tracker card visibility
/// Industry Pattern: Enum registry for feature toggles (Spotify, Apple Health)
enum TrackerCardType: String, Codable, CaseIterable, Identifiable {
    case currentWeight = "current_weight_card"
    case milestone = "milestone_card"
    case chart = "chart_card"
    case stats = "stats_card"
    case history = "history_card"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .currentWeight: return "Current Weight"
        case .milestone: return "Milestone"
        case .chart: return "Chart"
        case .stats: return "Statistics"
        case .history: return "History"
        }
    }

    var description: String {
        switch self {
        case .currentWeight: return "Latest weight with progress tracking"
        case .milestone: return "Progress ring with milestone tracking"
        case .chart: return "Weight trend chart"
        case .stats: return "Weight statistics summary"
        case .history: return "Weight entry history list"
        }
    }

    // REMOVED: visibilityKey - now managed by TrackerCardManager internally
    // All visibility state goes through TrackerCardManager.shared.isCardVisible()
}

/// Progress Story card types that can be hidden/shown
/// Used in Control Center for managing Progress Story card visibility
/// Industry Pattern: Same as TrackerCardType - enum registry for feature toggles
enum ProgressStoryCardType: String, Codable, CaseIterable, Identifiable {
    case coachBar = "progress_story_coach_bar_card"  // v1.2: Coach Bar
    case sevenDay = "progress_story_7day_card"
    case thirtyDay = "progress_story_30day_card"
    case banner = "progress_story_banner_card"
    case reflection = "progress_story_reflection_card"  // v1.2b/v1.2c: Reflection Nudge
    case recap = "progress_story_recap_card"
    case didYouKnow = "progress_story_tip_card"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .coachBar: return "Coach Bar"
        case .sevenDay: return "7-Day Trend"
        case .thirtyDay: return "30-Day Trend"
        case .banner: return "Progress Banner"
        case .reflection: return "Reflection Prompts"
        case .recap: return "Progress Recap"
        case .didYouKnow: return "Did You Know"
        }
    }

    var description: String {
        switch self {
        case .coachBar: return "Behavioral micro-copy under subtitle"
        case .sevenDay: return "7-day weight trend card"
        case .thirtyDay: return "30-day weight trend card"
        case .banner: return "Motivational progress message"
        case .reflection: return "Micro-planning prompts for habit building"
        case .recap: return "Net change, streak, and entries"
        case .didYouKnow: return "Educational weight loss tip"
        }
    }
}

/// Shared opt-out manager accessible from anywhere in the app
/// Industry pattern: Singleton manager for app-wide state (like UserDefaults)
class ContentOptOutManager: ObservableObject {
    static let shared = ContentOptOutManager()

    @AppStorage("optedOutContentItems") private var optedOutContentData: Data = Data()
    @Published var optedOutContentItems: [ContentItem] = []

    private init() {
        loadOptedOutContent()
    }

    /// Load opted-out content items from @AppStorage
    private func loadOptedOutContent() {
        if let decoded = try? JSONDecoder().decode([ContentItem].self, from: optedOutContentData) {
            optedOutContentItems = decoded
        }
    }

    /// Save opted-out content items to @AppStorage
    private func saveOptedOutContent() {
        if let encoded = try? JSONEncoder().encode(optedOutContentItems) {
            optedOutContentData = encoded
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
}

// MARK: - Control Center Card Types

/// Card types for Weight Tracker Control Center
/// User can reorder these based on importance
enum ControlCenterCardType: String, Codable, CaseIterable, Identifiable {
    case goals = "goals"
    case notifications = "notifications"
    case insights = "insights"
    case sync = "sync"
    case history = "history"  // NEW: Weight History (moved from main screen)
    case experience = "experience"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .goals: return "Goals"
        case .notifications: return "Notifications"
        case .insights: return "Insights & Education"
        case .sync: return "Apple Health Sync"
        case .history: return "Weight History"  // NEW
        case .experience: return "Manage My Experience"
        }
    }

    var icon: String {
        switch self {
        case .goals: return "flag.fill"
        case .notifications: return "bell.fill"
        case .insights: return "lightbulb.fill"
        case .sync: return "arrow.triangle.2.circlepath"
        case .history: return "list.bullet.clipboard.fill"  // NEW: History icon
        case .experience: return "slider.horizontal.3"
        }
    }
}

// MARK: - Weight Control Center View

/// Weight Control Center - Premium card-based settings with reorderable cards
/// Reference: FAST-LIFe_Control_Center_Vision.md
/// Behavioral psychology: User personalization (IKEA effect)
struct WeightControlCenterView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var weightManager: WeightManager
    @EnvironmentObject var behavioralScheduler: BehavioralNotificationScheduler
    @Binding var showGoalLine: Bool
    @Binding var weightGoal: Double

    // Observe ContentOptOutManager for reactive UI updates
    @ObservedObject private var optOutManager = ContentOptOutManager.shared

    // Observe TrackerCardManager for card visibility (Single Source of Truth)
    @ObservedObject private var cardManager = TrackerCardManager.shared

    // Observe ProgressStoryCardManager for Progress Story card visibility (Single Source of Truth)
    @ObservedObject private var progressStoryCardManager = ProgressStoryCardManager.shared

    // Card order persistence - default: Goals → Notifications → Insights → Sync → History → Experience
    @AppStorage("weightControlCenterCardOrder") private var cardOrderData: Data = Data()
    @State private var cardOrder: [ControlCenterCardType] = [.goals, .notifications, .insights, .sync, .history, .experience]

    // Drag and drop state (Hub pattern)
    @State private var draggedCard: ControlCenterCardType?

    // Layer 4: Expand/collapse state for Control Center cards
    @AppStorage("controlCenterExpandedCards") private var expandedCardsData: Data = Data()
    @State private var expandedCards: Set<String> = []

    // Badge interaction: Track current highlighted item for cycling through opted-out content
    @State private var currentHighlightedItemIndex: Int = 0
    @State private var highlightedItemID: String? = nil  // Track which item to highlight by ID
    @State private var scrollViewProxy: ScrollViewProxy?
    @State private var badgeScale: CGFloat = 1.0  // Layer 6: Badge bounce animation

    // Weight goal editing
    @State private var weightGoalString: String = ""

    // Sync state (from original WeightSettingsView)
    @State private var localSyncEnabled: Bool = true
    @State private var userSyncPreference: Bool = true
    @State private var isSyncing: Bool = false
    @State private var showingSyncAlert: Bool = false
    @State private var syncMessage: String = ""
    @State private var hasHealthKitPermission: Bool = false
    @State private var permissionStatusMessage: String = ""
    @State private var canEnableSync: Bool = true
    @State private var lastSyncStatus: String = ""
    @State private var showingWeightSyncDetails: Bool = false
    @State private var showingSyncPreferenceDialog: Bool = false

    // User experience opt-out preferences (Manage My Experience card)
    // Reference: Fast_LIFe_Control_Center_Gameplan.md §3
    @AppStorage("experienceOptOut_trackerCards") private var optOutTrackerCards: Bool = false
    @AppStorage("experienceOptOut_educationalInsights") private var optOutEducationalInsights: Bool = false
    @AppStorage("experienceOptOut_behavioralNudges") private var optOutBehavioralNudges: Bool = false
    @AppStorage("experienceOptOut_motivationalMessages") private var optOutMotivationalMessages: Bool = false
    @AppStorage("experienceOptOut_progressSummaries") private var optOutProgressSummaries: Bool = false

    // Granular opt-out system: Individual content items
    // Stores list of ContentItem objects that user has opted out of
    @AppStorage("optedOutContentItems") private var optedOutContentData: Data = Data()
    @State private var optedOutContentItems: [ContentItem] = []

    // UserDefaults keys
    private let userDefaults = UserDefaults.standard
    private let hasCompletedInitialImportKey = "weightHasCompletedInitialImport"

    // Restore all confirmation alert
    @State private var showingRestoreAllAlert = false

    // MARK: - Computed Properties

    /// Determines if the floating "Restore All" button should be shown
    /// Shows when ANY content is hidden or opted out:
    /// - Category opt-outs (Weight Tracker Cards, Educational Insights, Behavioral Nudges, etc.)
    /// - Individual content opt-outs (specific tips, nudges, messages, summaries)
    /// - Hidden tracker cards (Milestone, Chart, Stats, History)
    /// - Hidden Progress Story cards (7-Day, 30-Day, Banner, Recap, Did You Know)
    ///
    /// Scalable: Automatically handles new categories without code changes
    private var shouldShowRestoreButton: Bool {
        // 1. Check category opt-outs (Weight Tracker Cards + Content Categories)
        let hasCategoryOptOuts = optOutTrackerCards ||
                                 optOutEducationalInsights ||
                                 optOutBehavioralNudges ||
                                 optOutMotivationalMessages ||
                                 optOutProgressSummaries

        // 2. Check individual content opt-outs
        let hasIndividualOptOuts = !optOutManager.optedOutContentItems.isEmpty

        // 3. Check hidden tracker cards (via TrackerCardManager - Single Source of Truth)
        let hasHiddenTrackerCards = TrackerCardType.allCases.contains { cardType in
            !cardManager.isCardVisible(cardType)
        }

        // 4. Check hidden Progress Story cards (via ProgressStoryCardManager - Single Source of Truth)
        let hasHiddenProgressStoryCards = ProgressStoryCardType.allCases.contains { cardType in
            !progressStoryCardManager.isCardVisible(cardType)
        }

        return hasCategoryOptOuts || hasIndividualOptOuts || hasHiddenTrackerCards || hasHiddenProgressStoryCards
    }

    var body: some View {
        ZStack {
            // Luxury gradient background (matches Weight Tracker)
            LinearGradient(
                colors: [
                    Color(red: 10/255, green: 18/255, blue: 36/255),
                    Color(red: 18/255, green: 28/255, blue: 56/255)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header section (fixed at top)
                VStack(spacing: 4) {
                    // UX/UI Fix #3: Match Weight Tracker title size (34pt)
                    // Issue #1: Center title + apply Weight Tracker cyan gradient styling
                    Text("Control Center")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.4, green: 0.8, blue: 0.9),  // Cyan
                                    Color(red: 0.3, green: 0.7, blue: 1.0)   // Light blue
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(maxWidth: .infinity, alignment: .center)  // Centered
                        .padding(.horizontal, 20)
                        .padding(.top, 8)

                    // REFINEMENT #1: Split instructions into 2 lines
                    // Behavioral Science: Chunking for cognitive fluency
                    // UX/UI Fix #4: Increased subtitle font sizes for accessibility
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Customize your Weight Tracker experience.")
                            .font(.system(size: 18, weight: .medium))  // Increased from 17
                            .foregroundColor(Theme.ColorToken.textSecondary)

                        Text("Drag cards to reorder.")
                            .font(.system(size: 17, weight: .regular))  // Increased from 16
                            .foregroundColor(Theme.ColorToken.textSecondary.opacity(0.8))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
                }

                // ScrollView with reorderable cards (Hub pattern - perfect alignment)
                // Using .onDrag/.onDrop instead of List+.onMove to avoid layout issues
                // Reference: HubView.swift lines 65-88
                // Layer 3: Wrapped in ScrollViewReader for smooth scroll-to-item functionality
                ScrollView {
                    ScrollViewReader { proxy in
                        LazyVStack(spacing: 12) {
                            ForEach(cardOrder) { cardType in
                                cardView(for: cardType)
                                    .onDrag {
                                        // Hub pattern: NSItemProvider for drag/drop
                                        self.draggedCard = cardType
                                        return NSItemProvider(object: cardType.rawValue as NSString)
                                    }
                                    .onDrop(of: [.text], delegate: CardDropDelegate(
                                        card: cardType,
                                        cardOrder: $cardOrder,
                                        draggedCard: $draggedCard,
                                        saveAction: saveCardOrder
                                    ))
                            }

                            // About section (fixed at bottom)
                            aboutCard
                        }
                        .padding(.horizontal, 20)  // Single container padding (Hub pattern)
                        .padding(.top, 8)
                        .onAppear {
                            // Capture ScrollViewProxy for badge interaction
                            scrollViewProxy = proxy
                        }
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    // Dismiss keyboard
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)

                    // Update weight goal if valid
                    if let newGoal = Double(weightGoalString), newGoal > 0 {
                        weightGoal = newGoal
                    }
                    dismiss()
                }
                .foregroundColor(Theme.ColorToken.textPrimary)
                .fontWeight(.semibold)
            }

            // Keyboard toolbar for decimal pad
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
                .foregroundColor(Theme.ColorToken.accentPrimary)
                .fontWeight(.semibold)
            }
        }
        .onAppear {
            loadCardOrder()
            loadExpandedCards()  // Layer 4: Load expansion state
            loadOptedOutContent()  // Load opted-out content items
            weightGoalString = String(format: "%.1f", weightGoal)
            userSyncPreference = weightManager.syncWithHealthKit
            updatePermissionStatus()
            loadLastSyncStatus()
            updateToggleState()
        }
        .alert("Sync Status", isPresented: $showingSyncAlert) {
            if syncMessage.contains("Permission denied") || syncMessage.contains("enable weight access") {
                let authStatus = HealthKitManager.shared.getWeightAuthorizationStatus()

                if authStatus == .notDetermined {
                    Button("Try Again") {
                        syncWithHealthKit()
                    }
                } else {
                    Button("OK") { }
                }
                Button("Cancel", role: .cancel) { }
            } else {
                Button("OK", role: .cancel) { }
            }
        } message: {
            Text(syncMessage)
        }
        .alert("Import Weight Data", isPresented: $showingSyncPreferenceDialog) {
            Button("Import All Historical Data") {
                performHistoricalSync()
            }
            Button("Future Data Only") {
                performFutureOnlySync()
            }
            Button("Cancel", role: .cancel) {
                userSyncPreference = false
                localSyncEnabled = false
                updateToggleState()
            }
        } message: {
            Text("Choose how to sync your weight data with Apple Health. You can import all your historical weight entries or start fresh with only future entries.")
        }
        .alert("Restore All Content", isPresented: $showingRestoreAllAlert) {
            Button("Yes, Restore All", role: .destructive) {
                restoreAllToDefault()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will restore all hidden tracker cards and opted-out content to default. Are you sure?")
        }
    }

    // MARK: - Card Views

    @ViewBuilder
    private func cardView(for cardType: ControlCenterCardType) -> some View {
        let isExpanded = isCardExpanded(cardType)

        VStack(spacing: 0) {
            // Card Header (Hub pattern - no visible drag handle, long-press to drag)
            HStack(spacing: 12) {
                // Card icon
                Image(systemName: cardType.icon)
                    .foregroundColor(Theme.ColorToken.accentPrimary)
                    .font(.system(size: 20, weight: .semibold))

                // Card title
                Text(cardType.title)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Theme.ColorToken.textPrimaryOnDark)

                Spacer()

                // Badge for Manage My Experience card showing count of opted-out categories + items + hidden cards
                // Interactive: Tapping cycles through opted-out items with smooth scroll
                if cardType == .experience {
                    let categoryOptOutCount = [optOutTrackerCards, optOutEducationalInsights, optOutBehavioralNudges, optOutMotivationalMessages, optOutProgressSummaries].filter({ $0 }).count
                    let individualOptOutCount = optOutManager.optedOutContentItems.count
                    let hiddenTrackerCardsCount = TrackerCardType.allCases.filter { cardType in
                        !cardManager.isCardVisible(cardType)
                    }.count
                    let hiddenProgressStoryCardsCount = ProgressStoryCardType.allCases.filter { cardType in
                        !progressStoryCardManager.isCardVisible(cardType)
                    }.count
                    let totalOptOutCount = categoryOptOutCount + individualOptOutCount + hiddenTrackerCardsCount + hiddenProgressStoryCardsCount

                    if totalOptOutCount > 0 {
                        Button(action: {
                            // Show restore all confirmation alert
                            showingRestoreAllAlert = true
                        }) {
                            Text("\(totalOptOutCount)")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(Theme.ColorToken.textPrimaryOnDark)
                                .frame(minWidth: 24, minHeight: 24)
                                .background(
                                    Circle()
                                        .fill(Theme.ColorToken.stateWarning)
                                )
                        }
                        .buttonStyle(.plain)
                        .scaleEffect(badgeScale)  // Layer 6: Bounce animation
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: badgeScale)
                        .accessibilityLabel("\(totalOptOutCount) \(totalOptOutCount == 1 ? "item" : "items") opted out")
                        .accessibilityHint("Tap to restore all hidden content")
                        .onAppear {
                            // DEBUG: Log badge calculation components
                            AppLogger.debug("Badge count breakdown:", category: AppLogger.ui)
                            AppLogger.debug("  categoryOptOutCount: \(categoryOptOutCount)", category: AppLogger.ui)
                            AppLogger.debug("  individualOptOutCount: \(individualOptOutCount)", category: AppLogger.ui)
                            AppLogger.debug("  hiddenTrackerCardsCount: \(hiddenTrackerCardsCount)", category: AppLogger.ui)
                            AppLogger.debug("  hiddenProgressStoryCardsCount: \(hiddenProgressStoryCardsCount)", category: AppLogger.ui)
                            AppLogger.debug("  TOTAL: \(totalOptOutCount)", category: AppLogger.ui)
                        }
                    }
                }

                // Layer 4: Chevron expand/collapse button
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        toggleCardExpansion(cardType)
                    }
                }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Theme.ColorToken.textSecondaryOnDark)
                }
                .buttonStyle(.plain)
            }
            .padding(16)
            .background(Theme.ColorToken.cardHeaderOnDark)

            // Layer 4: Show content only when expanded
            if isExpanded {
                Divider()
                    .background(Theme.ColorToken.dividerOnDark)

                // Card Content
                cardContent(for: cardType)
                    .padding(16)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Theme.ColorToken.cardOnDark)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Theme.ColorToken.shadowCardOnDark, radius: 16, x: 0, y: 8)
    }

    @ViewBuilder
    private func cardContent(for cardType: ControlCenterCardType) -> some View {
        switch cardType {
        case .goals:
            goalsCardContent
        case .notifications:
            notificationsCardContent
        case .insights:
            insightsCardContent
        case .sync:
            syncCardContent
        case .history:
            historyCardContent
        case .experience:
            experienceCardContent
        }
    }

    // MARK: - Goals Card

    private var goalsCardContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Benefit micro-explainer (Sprint 1)
            Text("Tracking your weight helps you see progress from the inside out — long before it shows in the mirror.")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Theme.ColorToken.textSecondaryOnDark)
                .fixedSize(horizontal: false, vertical: true)

            Divider()
                .background(Theme.ColorToken.dividerOnDark)

            // Show goal line toggle
            Toggle(isOn: $showGoalLine) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Show Goal Line on Chart")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Theme.ColorToken.textPrimaryOnDark)
                    Text("Display your target weight on the progress chart")
                        .font(.system(size: 13))
                        .foregroundColor(Theme.ColorToken.textSecondaryOnDark)
                }
            }
            .tint(Theme.ColorToken.accentPrimary)

            if showGoalLine {
                Divider()
                    .background(Theme.ColorToken.dividerOnDark)

                // Goal weight editor - Centered design with grouped value+unit
                // UX/UI Fix #1: Value and unit grouped and centered together
                VStack(alignment: .center, spacing: 8) {
                    // "Goal Weight" label - natural width
                    Text("Goal Weight")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Theme.ColorToken.textSecondaryOnDark)

                    // Compact teal container - matches gold pill size
                    // "150.0" perfectly centered under "Goal Weight" label
                    HStack(spacing: 4) {
                        TextField("Enter goal", text: $weightGoalString)
                            .keyboardType(.decimalPad)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(Theme.ColorToken.textPrimaryOnDark)
                            .multilineTextAlignment(.center)
                            .monospacedDigit()  // Sprint 1: Prevents jitter when digits change
                            .fixedSize()  // Shrink to content width
                            .onChange(of: weightGoalString) { _, newValue in
                                // UX/UI Fix #2: Restrict to one decimal place, max 999.9
                                formatWeightGoalInput(newValue)
                            }

                        Text("lbs")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Theme.ColorToken.textPrimaryOnDark)
                            .accessibilityHidden(true)  // Sprint 1: Avoid redundant "lbs" announcement
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Goal weight \(weightGoalString) pounds")
                    .accessibilityHint("Double tap to edit")
                    .padding(.leading, 28)  // Shift entire HStack right to center "150.0"
                    .padding(.trailing, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Theme.ColorToken.accentPrimary.opacity(0.2))
                    )
                    // REFINEMENT #3: Enhanced progress metric with pill background
                    // Behavioral Science: Goal gradient effect + visual reward
                    // Issue #3: Centered horizontally
                    if let goal = Double(weightGoalString),
                       goal > 0,
                       let currentWeight = weightManager.latestWeight?.weight {
                        let toGo = currentWeight - goal
                        if toGo > 0 {
                            HStack(spacing: 8) {
                                Image(systemName: "target")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(Theme.ColorToken.accentGold)
                                Text("\(String(format: "%.1f", toGo)) lbs to go")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(Theme.ColorToken.accentGold)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                Capsule()
                                    .fill(Theme.ColorToken.accentGold.opacity(0.15))
                                    .overlay(
                                        Capsule()
                                            .stroke(Theme.ColorToken.accentGold.opacity(0.3), lineWidth: 1)
                                    )
                            )
                            .shadow(color: Theme.ColorToken.accentGold.opacity(0.2), radius: 8, x: 0, y: 4)
                            .frame(maxWidth: .infinity)  // Center horizontally
                            .padding(.top, 12)
                        }
                    }
                }
                .frame(maxWidth: .infinity)  // Center the entire VStack horizontally
            }
        }
    }

    // MARK: - Notifications Card

    private var notificationsCardContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Sprint 1: Remove "coming soon" vaporware feel
            Text("Personalized nudges to build daily streaks.")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Theme.ColorToken.textSecondaryOnDark)

            // TODO: Add notification toggles, quiet hours, smart reminders
            // Reference: FAST-LIFe_Control_Center_Vision.md §B
        }
    }

    // MARK: - Insights Card

    private var insightsCardContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Sprint 1: Remove "coming soon" vaporware feel
            Text("Smart tips based on your trends.")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Theme.ColorToken.textSecondaryOnDark)

            // TODO: Add contextual micro-lessons
            // Reference: FAST-LIFe_Control_Center_Vision.md §D
        }
    }

    // MARK: - Sync Card

    private var syncCardContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Sync toggle
            Toggle(isOn: $localSyncEnabled) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Sync with Apple Health")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Theme.ColorToken.textPrimaryOnDark)
                    // Sprint 1: Benefit copy - multi-line format (1 sentence per line)
                    Text("Auto-import your weight from Apple Health.")
                        .font(.system(size: 13))
                        .foregroundColor(Theme.ColorToken.textSecondaryOnDark)
                    Text("No manual entry.")
                        .font(.system(size: 13))
                        .foregroundColor(Theme.ColorToken.textSecondaryOnDark)
                    Text(hasHealthKitPermission ? "Ready to sync" : "Not synced")
                        .font(.system(size: 12))
                        .foregroundColor(hasHealthKitPermission ? Theme.ColorToken.accentPrimary : Theme.ColorToken.textSecondaryOnDark)
                }
            }
            .tint(Theme.ColorToken.accentPrimary)
            .disabled(!canEnableSync)
            .onChange(of: localSyncEnabled) { _, newValue in
                userSyncPreference = newValue
                if canEnableSync {
                    weightManager.setSyncPreference(newValue)
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    updatePermissionStatus()
                    updateToggleState()
                }
            }

            if localSyncEnabled {
                Divider()
                    .background(Theme.ColorToken.dividerOnDark)

                // Sync button
                Button(action: {
                    syncWithHealthKit()
                }) {
                    HStack(spacing: 8) {
                        if isSyncing {
                            ProgressView()
                                .tint(Theme.ColorToken.textPrimaryOnDark)
                        } else {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        Text(isSyncing ? "Syncing..." : "Sync Now")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(Theme.ColorToken.textPrimaryOnDark)
                    .frame(maxWidth: .infinity)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Theme.ColorToken.accentPrimary)
                    )
                }
                .disabled(isSyncing || !hasHealthKitPermission)
                .opacity((isSyncing || !hasHealthKitPermission) ? 0.5 : 1.0)
            }

            // Status message
            if !hasHealthKitPermission {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(Theme.ColorToken.stateWarning)
                    Text(permissionStatusMessage)
                        .font(.system(size: 13))
                        .foregroundColor(Theme.ColorToken.textSecondaryOnDark)
                }
            } else if !lastSyncStatus.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Theme.ColorToken.accentPrimary)
                    Text(lastSyncStatus)
                        .font(.system(size: 13))
                        .foregroundColor(Theme.ColorToken.textSecondaryOnDark)
                }
            }

            // Behavioral insight: Trust badge
            // Issue #4: Centered horizontally
            if hasHealthKitPermission && localSyncEnabled {
                HStack(spacing: 8) {
                    Image(systemName: "lock.shield.fill")
                        .foregroundColor(Theme.ColorToken.accentInfo)
                        .font(.system(size: 12))
                    Text("Your data is secure & up-to-date")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Theme.ColorToken.textSecondaryOnDark)
                }
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Theme.ColorToken.accentInfo.opacity(0.15))
                )
                .frame(maxWidth: .infinity)  // Center horizontally
            }
        }
    }

    // MARK: - History Card

    private var historyCardContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Sprint 1: Benefit copy - explain why history matters
            Text("Review and manage your weight entries.")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Theme.ColorToken.textSecondaryOnDark)

            // Show weight history list (reusing existing component)
            WeightHistoryListView(weightManager: weightManager)
        }
    }

    // MARK: - Manage My Experience Card

    private var experienceCardContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Subtitle: Purpose of this card
            Text("Control which tips, nudges, and summaries you see (Opt-outs live here).")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Theme.ColorToken.textSecondaryOnDark)
                .fixedSize(horizontal: false, vertical: true)

            Divider()
                .background(Theme.ColorToken.dividerOnDark)

            // Weight Tracker Cards Toggle (Category-level control)
            trackerCardsToggle()

            Divider()
                .background(Theme.ColorToken.dividerOnDark)

            // Educational Insights Toggle (Category-level control)
            categoryToggle(
                isOn: Binding(
                    get: { !self.optOutEducationalInsights },
                    set: { self.optOutEducationalInsights = !$0 }
                ),
                title: "Educational Insights",
                description: "Learn about weight tracking science and best practices",
                category: .educationalInsights
            )

            Divider()
                .background(Theme.ColorToken.dividerOnDark)

            // Behavioral Nudges Toggle (Category-level control)
            categoryToggle(
                isOn: Binding(
                    get: { !self.optOutBehavioralNudges },
                    set: { self.optOutBehavioralNudges = !$0 }
                ),
                title: "Behavioral Nudges",
                description: "Gentle reminders to log weight and build streaks",
                category: .behavioralNudges
            )

            Divider()
                .background(Theme.ColorToken.dividerOnDark)

            // Motivational Messages Toggle (Category-level control)
            categoryToggle(
                isOn: Binding(
                    get: { !self.optOutMotivationalMessages },
                    set: { self.optOutMotivationalMessages = !$0 }
                ),
                title: "Motivational Messages",
                description: "Encouragement when you hit milestones or new lows",
                category: .motivationalMessages
            )

            Divider()
                .background(Theme.ColorToken.dividerOnDark)

            // Progress Summaries Toggle (Master toggle for all Progress Story cards)
            progressStoryCardsToggle()

            // Floating "Restore All" button
            // Shows when ANY content is hidden: categories, individual items, or tracker cards
            // Triggers confirmation alert (same as badge)
            if shouldShowRestoreButton {
                Divider()
                    .background(Theme.ColorToken.dividerOnDark)

                Button(action: {
                    // Show confirmation alert (same behavior as badge)
                    showingRestoreAllAlert = true
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Restore All")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(Theme.ColorToken.textPrimaryOnDark)
                    .frame(maxWidth: .infinity)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Theme.ColorToken.accentGold.opacity(0.3))
                    )
                }
            }
        }
    }

    // Helper view for category toggles with individual opt-out items
    @ViewBuilder
    private func categoryToggle(isOn: Binding<Bool>, title: String, description: String, category: ContentCategory) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Category-level toggle
            Toggle(isOn: isOn) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Theme.ColorToken.textPrimaryOnDark)
                    Text(description)
                        .font(.system(size: 13))
                        .foregroundColor(Theme.ColorToken.textSecondaryOnDark)
                }
            }
            .tint(Theme.ColorToken.accentPrimary)

            // Show individual opted-out items for this category (if any)
            let optedOutItems = optOutManager.optedOutContentItems.filter { $0.category == category }
            if !optedOutItems.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    // "Individual opt-outs" header
                    Text("Individual opt-outs:")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Theme.ColorToken.textSecondaryOnDark.opacity(0.7))
                        .padding(.leading, 16)
                        .padding(.top, 4)

                    // List of opted-out items
                    // Layer 3: Each item has .id() for ScrollViewReader targeting
                    ForEach(Array(optedOutItems.enumerated()), id: \.element.id) { index, item in
                        let isHighlighted = highlightedItemID == item.id

                        HStack(spacing: 8) {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 14))
                                .foregroundColor(Theme.ColorToken.stateWarning)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.displayText)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(Theme.ColorToken.textPrimaryOnDark)
                                Text("Opted out \(item.timestamp.formatted(date: .abbreviated, time: .omitted))")
                                    .font(.system(size: 11))
                                    .foregroundColor(Theme.ColorToken.textSecondaryOnDark.opacity(0.6))
                            }

                            Spacer()

                            // Restore button for individual item
                            Button(action: {
                                optOutManager.optInContent(id: item.id)
                            }) {
                                Text("Restore")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(Theme.ColorToken.accentPrimary)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Theme.ColorToken.textSecondaryOnDark.opacity(0.1))
                        )
                        .overlay(
                            // Layer 4: Gold border pulse when highlighted
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Theme.ColorToken.accentGold, lineWidth: isHighlighted ? 2 : 0)
                                .opacity(isHighlighted ? 1 : 0)
                        )
                        .shadow(
                            color: isHighlighted ? Theme.ColorToken.accentGold.opacity(0.3) : .clear,
                            radius: isHighlighted ? 8 : 0,
                            x: 0,
                            y: 0
                        )
                        .padding(.horizontal, 8)
                        .id(item.id)  // Layer 3: Enable ScrollViewReader targeting
                    }
                }
            }
        }
    }

    // Helper view for Weight Tracker Cards toggle with hidden cards list
    @ViewBuilder
    private func trackerCardsToggle() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Master toggle for ALL Weight Tracker Cards
            // When ON: Show all 5 cards | When OFF: Hide all 5 cards
            // Industry Pattern: Apple Health section-level toggles
            // Following "simple method first" strategy
            Toggle(isOn: Binding(
                get: {
                    // Toggle is ON if ALL cards are visible
                    TrackerCardType.allCases.allSatisfy { cardManager.isCardVisible($0) }
                },
                set: { newValue in
                    // When toggle changes: Show or hide ALL 5 cards
                    for cardType in TrackerCardType.allCases {
                        if newValue {
                            cardManager.showCard(cardType)
                        } else {
                            cardManager.hideCard(cardType)
                        }
                    }
                    // Also update legacy @AppStorage flag (for backwards compatibility)
                    self.optOutTrackerCards = !newValue
                }
            )) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Weight Tracker Cards")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Theme.ColorToken.textPrimaryOnDark)
                    Text("Manage which cards appear on your tracker")
                        .font(.system(size: 13))
                        .foregroundColor(Theme.ColorToken.textSecondaryOnDark)
                }
            }
            .tint(Theme.ColorToken.accentPrimary)

            // Show hidden tracker cards (if any) - via TrackerCardManager (Single Source of Truth)
            let hiddenCards = TrackerCardType.allCases.filter { cardType in
                !cardManager.isCardVisible(cardType)
            }

            if !hiddenCards.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    // "Hidden cards" header
                    Text("Hidden cards:")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Theme.ColorToken.textSecondaryOnDark.opacity(0.7))
                        .padding(.leading, 16)
                        .padding(.top, 4)

                    // List of hidden cards
                    ForEach(hiddenCards) { cardType in
                        HStack(spacing: 8) {
                            Image(systemName: "eye.slash.fill")
                                .font(.system(size: 14))
                                .foregroundColor(Theme.ColorToken.stateWarning)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(cardType.displayName)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(Theme.ColorToken.textPrimaryOnDark)
                                Text(cardType.description)
                                    .font(.system(size: 11))
                                    .foregroundColor(Theme.ColorToken.textSecondaryOnDark.opacity(0.6))
                            }

                            Spacer()

                            // Restore button for individual card (via TrackerCardManager)
                            Button(action: {
                                cardManager.showCard(cardType)
                            }) {
                                Text("Restore")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(Theme.ColorToken.accentPrimary)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Theme.ColorToken.textSecondaryOnDark.opacity(0.1))
                        )
                        .padding(.horizontal, 8)
                    }
                }
            }
        }
    }

    // Helper view for Progress Story Cards toggle with hidden cards list
    @ViewBuilder
    private func progressStoryCardsToggle() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Master toggle for ALL Progress Story Cards
            // When ON: Show all 5 cards | When OFF: Hide all 5 cards
            // Industry Pattern: Apple Health section-level toggles (same as Weight Tracker Cards)
            // Following "simple method first" strategy
            Toggle(isOn: Binding(
                get: {
                    // Toggle is ON if ALL Progress Story cards are visible
                    ProgressStoryCardType.allCases.allSatisfy { progressStoryCardManager.isCardVisible($0) }
                },
                set: { newValue in
                    // When toggle changes: Show or hide ALL 5 Progress Story cards
                    for cardType in ProgressStoryCardType.allCases {
                        if newValue {
                            progressStoryCardManager.showCard(cardType)
                        } else {
                            progressStoryCardManager.hideCard(cardType)
                        }
                    }
                    // Also update legacy @AppStorage flag (for backwards compatibility)
                    self.optOutProgressSummaries = !newValue
                }
            )) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your Progress Journey")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Theme.ColorToken.textPrimaryOnDark)
                    Text("Weekly recaps showing trends and wins")
                        .font(.system(size: 13))
                        .foregroundColor(Theme.ColorToken.textSecondaryOnDark)
                }
            }
            .tint(Theme.ColorToken.accentPrimary)

            // Show hidden Progress Story cards (if any) - via ProgressStoryCardManager (Single Source of Truth)
            let hiddenCards = ProgressStoryCardType.allCases.filter { cardType in
                !progressStoryCardManager.isCardVisible(cardType)
            }

            if !hiddenCards.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    // "Hidden cards" header
                    Text("Hidden cards:")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Theme.ColorToken.textSecondaryOnDark.opacity(0.7))
                        .padding(.leading, 16)
                        .padding(.top, 4)

                    // List of hidden Progress Story cards
                    ForEach(hiddenCards) { cardType in
                        HStack(spacing: 8) {
                            Image(systemName: "eye.slash.fill")
                                .font(.system(size: 14))
                                .foregroundColor(Theme.ColorToken.stateWarning)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(cardType.displayName)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(Theme.ColorToken.textPrimaryOnDark)
                                Text(cardType.description)
                                    .font(.system(size: 11))
                                    .foregroundColor(Theme.ColorToken.textSecondaryOnDark.opacity(0.6))
                            }

                            Spacer()

                            // Restore button for individual card (via ProgressStoryCardManager)
                            Button(action: {
                                progressStoryCardManager.showCard(cardType)
                            }) {
                                Text("Restore")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(Theme.ColorToken.accentPrimary)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Theme.ColorToken.textSecondaryOnDark.opacity(0.1))
                        )
                        .padding(.horizontal, 8)
                    }
                }
            }
        }
    }

    // MARK: - Restore All Functionality

    /// Restore all content to default state
    /// Restores: Hidden tracker cards, hidden Progress Story cards, category opt-outs, individual opt-outs
    private func restoreAllToDefault() {
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

        // 4. Clear all individual opt-outs
        optOutManager.optedOutContentItems.removeAll()
        if let encoded = try? JSONEncoder().encode([ContentItem]()) {
            optedOutContentData = encoded
        }

        // Haptic feedback for confirmation
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    // MARK: - About Card (Fixed at Bottom)

    private var aboutCard: some View {
        let isExpanded = expandedCards.contains("about")

        return VStack(spacing: 0) {
            // Card Header
            HStack(spacing: 12) {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(Theme.ColorToken.accentInfo)
                    .font(.system(size: 20, weight: .semibold))

                Text("About")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Theme.ColorToken.textPrimaryOnDark)

                Spacer()

                // Layer 4: Chevron expand/collapse button
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        if expandedCards.contains("about") {
                            expandedCards.remove("about")
                        } else {
                            expandedCards.insert("about")
                        }
                        saveExpandedCards()
                    }
                }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Theme.ColorToken.textSecondaryOnDark)
                }
                .buttonStyle(.plain)
            }
            .padding(16)
            .background(Theme.ColorToken.cardHeaderOnDark)

            // Layer 4: Show content only when expanded
            if isExpanded {
                Divider()
                    .background(Theme.ColorToken.dividerOnDark)

                // About content
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Total Entries")
                            .font(.system(size: 16))
                            .foregroundColor(Theme.ColorToken.textSecondaryOnDark)
                        Spacer()
                        Text("\(weightManager.weightEntries.count)")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Theme.ColorToken.textPrimaryOnDark)
                    }

                    // Behavioral insight: Identity reinforcement
                    if let oldest = weightManager.weightEntries.sorted(by: { $0.date < $1.date }).first {
                        Divider()
                            .background(Theme.ColorToken.dividerOnDark)

                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Tracking Since")
                                    .font(.system(size: 16))
                                    .foregroundColor(Theme.ColorToken.textSecondaryOnDark)
                                Spacer()
                                Text(oldest.date.formatted(date: .abbreviated, time: .omitted))
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(Theme.ColorToken.textPrimaryOnDark)
                            }

                            // Identity badge
                            HStack(spacing: 6) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 11))
                                    .foregroundColor(Theme.ColorToken.accentGold)
                                Text("You've logged \(weightManager.weightEntries.count) entries since \(Calendar.current.component(.year, from: oldest.date))")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(Theme.ColorToken.textSecondaryOnDark)
                            }
                            .padding(.top, 4)
                        }
                    }
                }
                .padding(16)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Theme.ColorToken.cardOnDark)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Theme.ColorToken.shadowCardOnDark, radius: 16, x: 0, y: 8)
    }

    // MARK: - Layer 4: Expansion State Management

    /// Check if a card is currently expanded
    private func isCardExpanded(_ cardType: ControlCenterCardType) -> Bool {
        return expandedCards.contains(cardType.rawValue)
    }

    /// Toggle expansion state for a card
    private func toggleCardExpansion(_ cardType: ControlCenterCardType) {
        if expandedCards.contains(cardType.rawValue) {
            expandedCards.remove(cardType.rawValue)
        } else {
            expandedCards.insert(cardType.rawValue)
        }
        saveExpandedCards()
    }

    /// Load expanded cards from UserDefaults
    private func loadExpandedCards() {
        if let decoded = try? JSONDecoder().decode(Set<String>.self, from: expandedCardsData) {
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
            expandedCardsData = encoded
        }
    }

    // MARK: - Card Order Persistence

    private func loadCardOrder() {
        if let decoded = try? JSONDecoder().decode([ControlCenterCardType].self, from: cardOrderData) {
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

    private func saveCardOrder() {
        if let encoded = try? JSONEncoder().encode(cardOrder) {
            cardOrderData = encoded
        }
    }

    // MARK: - Sync Logic (From Original WeightSettingsView)

    private func syncWithHealthKit() {
        isSyncing = true

        let isAuthorized = HealthKitManager.shared.isWeightAuthorized()

        if !isAuthorized {
            HealthKitManager.shared.requestWeightAuthorization { success, error in
                if success {
                    DispatchQueue.main.async {
                        self.isSyncing = false
                        if self.hasCompletedInitialImport() {
                            self.performSync()
                        } else {
                            self.showingSyncPreferenceDialog = true
                        }
                    }
                } else {
                    isSyncing = false
                    syncMessage = error?.localizedDescription ?? "HealthKit authorization required. Enable weight access in Settings."
                    showingSyncAlert = true
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

    private func updatePermissionStatus() {
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

    private func updateToggleState() {
        if hasHealthKitPermission {
            localSyncEnabled = userSyncPreference
        } else {
            localSyncEnabled = false
        }
    }

    private func loadLastSyncStatus() {
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

    private func performSync() {
        let startDate = Calendar.current.date(byAdding: .year, value: -10, to: Date()) ?? Date()

        weightManager.syncFromHealthKitWithReset(startDate: startDate) { syncedCount, error in
            DispatchQueue.main.async {
                isSyncing = false

                if let error = error {
                    syncMessage = error.localizedDescription
                    showingSyncAlert = true
                } else {
                    if syncedCount > 0 {
                        syncMessage = "Successfully synced \(syncedCount) new weight entries from Apple Health."
                    } else {
                        let hasPermission = HealthKitManager.shared.isWeightAuthorized()
                        if hasPermission {
                            syncMessage = "Weight data is up to date. No new entries found in Apple Health."
                        } else {
                            syncMessage = "Permission denied. To enable weight sync, go to Settings → Privacy → Health."
                        }
                    }
                    showingSyncAlert = true

                    updatePermissionStatus()
                    loadLastSyncStatus()
                    updateToggleState()

                    if hasHealthKitPermission && userSyncPreference {
                        weightManager.setSyncPreference(true)
                    }
                }
            }
        }
    }

    private func performHistoricalSync() {
        markInitialImportCompleted()
        isSyncing = true

        let startDate = Calendar.current.date(byAdding: .year, value: -10, to: Date()) ?? Date()

        weightManager.syncFromHealthKitHistorical(startDate: startDate) { syncedCount, error in
            DispatchQueue.main.async {
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

    private func performFutureOnlySync() {
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

    private func hasCompletedInitialImport() -> Bool {
        return userDefaults.bool(forKey: hasCompletedInitialImportKey)
    }

    private func markInitialImportCompleted() {
        userDefaults.set(true, forKey: hasCompletedInitialImportKey)
        userDefaults.synchronize()
    }

    // MARK: - Weight Goal Input Formatting

    /// Format weight goal input to one decimal place, max 999.9
    /// UX/UI Fix #2: Industry standard for health apps
    private func formatWeightGoalInput(_ input: String) {
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

    /// Get opted-out items in visual top-to-bottom display order
    /// Matches the exact order items appear on screen in category sections
    private var visuallyOrderedOptedOutItems: [ContentItem] {
        // Define category display order (matches UI layout top-to-bottom)
        let categoryOrder: [ContentCategory] = [
            .educationalInsights,
            .behavioralNudges,
            .motivationalMessages,
            .progressSummaries
        ]

        // Build array in visual order by iterating through categories
        var orderedItems: [ContentItem] = []
        for category in categoryOrder {
            let itemsInCategory = optOutManager.optedOutContentItems.filter { $0.category == category }
            orderedItems.append(contentsOf: itemsInCategory)
        }

        return orderedItems
    }

    /// Cycle to next opted-out item when badge is tapped
    /// Industry pattern: Instagram stories badge, Spotify playlist scroll
    private func cycleToNextOptedOutItem() {
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
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation {
                highlightedItemID = nil
            }
        }

        // Layer 5: Haptic feedback - Light tap for premium feel
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        // Layer 6: Badge bounce animation (1.0 → 1.15 → 1.0)
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            badgeScale = 1.15
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                badgeScale = 1.0
            }
        }

        // Increment index for NEXT tap (after scrolling to current item)
        currentHighlightedItemIndex = (currentHighlightedItemIndex + 1) % allOptedOutItems.count
    }

    // MARK: - Opt-Out System Helper Functions

    /// Load opted-out content items from @AppStorage
    private func loadOptedOutContent() {
        if let decoded = try? JSONDecoder().decode([ContentItem].self, from: optedOutContentData) {
            optedOutContentItems = decoded
        }
    }

    /// Save opted-out content items to @AppStorage
    private func saveOptedOutContent() {
        if let encoded = try? JSONEncoder().encode(optedOutContentItems) {
            optedOutContentData = encoded
        }
    }

    /// Opt out of specific content item
    /// - Parameters:
    ///   - id: Unique identifier for the content
    ///   - category: Content category (educational, behavioral, motivational, progress)
    ///   - text: Display text shown in Manage My Experience
    func optOutContent(id: String, category: ContentCategory, text: String) {
        let newItem = ContentItem(id: id, category: category, displayText: text)

        // Check if already opted out
        if !optedOutContentItems.contains(where: { $0.id == id }) {
            optedOutContentItems.append(newItem)
            saveOptedOutContent()
        }
    }

    /// Opt back in to specific content item
    /// - Parameter id: Unique identifier for the content
    func optInContent(id: String) {
        optedOutContentItems.removeAll { $0.id == id }
        saveOptedOutContent()
    }

    /// Check if specific content is opted out
    /// - Parameter id: Unique identifier for the content
    /// - Returns: True if user has opted out of this content
    func isContentOptedOut(id: String) -> Bool {
        return optedOutContentItems.contains(where: { $0.id == id })
    }
}

// MARK: - Drag & Drop Delegate (Hub pattern)
// Reference: HubView.swift lines 177-205

struct CardDropDelegate: DropDelegate {
    let card: ControlCenterCardType
    @Binding var cardOrder: [ControlCenterCardType]
    @Binding var draggedCard: ControlCenterCardType?
    let saveAction: () -> Void

    func performDrop(info: DropInfo) -> Bool {
        guard let draggedCard = draggedCard else { return false }

        // Reorder logic following Hub's drag/drop pattern
        if let fromIndex = cardOrder.firstIndex(of: draggedCard),
           let toIndex = cardOrder.firstIndex(of: card) {

            withAnimation(.spring()) {
                cardOrder.move(fromOffsets: IndexSet(integer: fromIndex), toOffset: toIndex > fromIndex ? toIndex + 1 : toIndex)
            }

            // Save the new order
            saveAction()
        }

        self.draggedCard = nil
        return true
    }

    func dropEntered(info: DropInfo) {
        // Optional: Add visual feedback during drag
    }

    func dropExited(info: DropInfo) {
        // Optional: Remove visual feedback
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        WeightControlCenterView(
            weightManager: WeightManager(),
            showGoalLine: .constant(true),
            weightGoal: .constant(150.0)
        )
        .environmentObject(BehavioralNotificationScheduler())
    }
}
