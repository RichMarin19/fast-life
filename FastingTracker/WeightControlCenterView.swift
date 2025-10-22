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

// MARK: - TrackerCardType + CardTypeProtocol

extension TrackerCardType: CardTypeProtocol {
    // displayName already exists (lines 52-60)
    // No additional implementation needed - already conforms!
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

// MARK: - ProgressStoryCardType + CardTypeProtocol

extension ProgressStoryCardType: CardTypeProtocol {
    // displayName already exists (lines 97-106)
    // No additional implementation needed - already conforms!
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
/// Pattern: MVVM (ViewModel handles state and business logic)
struct WeightControlCenterView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel: WeightControlCenterViewModel
    @Binding var showGoalLine: Bool
    @Binding var weightGoal: Double

    // MARK: - Initialization

    init(weightManager: WeightManager,
         showGoalLine: Binding<Bool>,
         weightGoal: Binding<Double>) {
        // TEMPORARY: Using temporary BehavioralNotificationScheduler instance
        // The real instance is passed via .environmentObject in WeightTrackingView.swift:139
        // This temporary instance is only used for ViewModel initialization and won't be used
        _viewModel = StateObject(wrappedValue: WeightControlCenterViewModel(
            weightManager: weightManager,
            behavioralScheduler: BehavioralNotificationScheduler()
        ))
        _showGoalLine = showGoalLine
        _weightGoal = weightGoal
    }

    var body: some View {
        ZStack {
            // Luxury gradient background (matches Weight Tracker)
            LinearGradient(
                colors: [
                    Theme.ColorToken.bgDeepStart,
                    Theme.ColorToken.bgDeepMid
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
                        .font(DSTypography.screenTitle)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Theme.ColorToken.accentCyan,
                                    Theme.ColorToken.accentLightBlue
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
                            .font(DSTypography.subtitleLarge)  // Increased from 17
                            .foregroundColor(Theme.ColorToken.textSecondary)

                        Text("Drag cards to reorder.")
                            .font(DSTypography.subtitleEmphasized)  // Increased from 16
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
                            ForEach(viewModel.cardOrder) { cardType in
                                cardView(for: cardType)
                                    .onDrag {
                                        // Hub pattern: NSItemProvider for drag/drop
                                        viewModel.draggedCard = cardType
                                        return NSItemProvider(object: cardType.rawValue as NSString)
                                    }
                                    .onDrop(of: [.text], delegate: CardDropDelegate(
                                        card: cardType,
                                        cardOrder: $viewModel.cardOrder,
                                        draggedCard: $viewModel.draggedCard,
                                        saveAction: viewModel.saveCardOrder
                                    ))
                            }

                            // About section (fixed at bottom)
                            aboutCard
                        }
                        .padding(.horizontal, 20)  // Single container padding (Hub pattern)
                        .padding(.top, 8)
                        .onAppear {
                            // Capture ScrollViewProxy for badge interaction
                            viewModel.scrollViewProxy = proxy
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
                    if let newGoal = Double(viewModel.weightGoalString), newGoal > 0 {
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
            viewModel.loadCardOrder()
            viewModel.loadExpandedCards()
            viewModel.loadOptedOutContent()
            viewModel.weightGoalString = String(format: "%.1f", weightGoal)
            viewModel.userSyncPreference = viewModel.weightManager.syncWithHealthKit
            viewModel.updatePermissionStatus()
            viewModel.loadLastSyncStatus()
            viewModel.updateToggleState()
        }
        .alert("Sync Status", isPresented: $viewModel.showingSyncAlert) {
            if viewModel.syncMessage.contains("Permission denied") || viewModel.syncMessage.contains("enable weight access") {
                let authStatus = HealthKitManager.shared.getWeightAuthorizationStatus()

                if authStatus == .notDetermined {
                    Button("Try Again") {
                        viewModel.syncWithHealthKit()
                    }
                } else {
                    Button("OK") { }
                }
                Button("Cancel", role: .cancel) { }
            } else {
                Button("OK", role: .cancel) { }
            }
        } message: {
            Text(viewModel.syncMessage)
        }
        .alert("Import Weight Data", isPresented: $viewModel.showingSyncPreferenceDialog) {
            Button("Import All Historical Data") {
                viewModel.performHistoricalSync()
            }
            Button("Future Data Only") {
                viewModel.performFutureOnlySync()
            }
            Button("Cancel", role: .cancel) {
                viewModel.userSyncPreference = false
                viewModel.localSyncEnabled = false
                viewModel.updateToggleState()
            }
        } message: {
            Text("Choose how to sync your weight data with Apple Health. You can import all your historical weight entries or start fresh with only future entries.")
        }
        .alert("Restore All Content", isPresented: $viewModel.showingRestoreAllAlert) {
            Button("Yes, Restore All", role: .destructive) {
                viewModel.restoreAllToDefault()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will restore all hidden tracker cards and opted-out content to default. Are you sure?")
        }
    }

    // MARK: - Card Views

    @ViewBuilder
    private func cardView(for cardType: ControlCenterCardType) -> some View {
        let isExpanded = viewModel.isCardExpanded(cardType)

        VStack(spacing: 0) {
            // Card Header (Hub pattern - no visible drag handle, long-press to drag)
            HStack(spacing: 12) {
                // Card icon
                Image(systemName: cardType.icon)
                    .foregroundColor(Theme.ColorToken.accentPrimary)
                    .font(DSTypography.displayS)

                // Card title
                Text(cardType.title)
                    .font(DSTypography.displaySRounded)
                    .foregroundColor(Theme.ColorToken.textPrimaryOnDark)

                Spacer()

                // Badge for Manage My Experience card showing count of opted-out categories + items + hidden cards
                // Interactive: Tapping cycles through opted-out items with smooth scroll
                if cardType == .experience {
                    let categoryOptOutCount = [viewModel.optOutTrackerCards, viewModel.optOutEducationalInsights, viewModel.optOutBehavioralNudges, viewModel.optOutMotivationalMessages, viewModel.optOutProgressSummaries].filter({ $0 }).count
                    let individualOptOutCount = viewModel.optOutManager.optedOutContentItems.count
                    let hiddenTrackerCardsCount = TrackerCardType.allCases.filter { cardType in
                        !viewModel.cardManager.isCardVisible(cardType)
                    }.count
                    let hiddenProgressStoryCardsCount = ProgressStoryCardType.allCases.filter { cardType in
                        !viewModel.progressStoryCardManager.isCardVisible(cardType)
                    }.count
                    let totalOptOutCount = categoryOptOutCount + individualOptOutCount + hiddenTrackerCardsCount + hiddenProgressStoryCardsCount

                    if totalOptOutCount > 0 {
                        Button(action: {
                            // Show restore all confirmation alert
                            viewModel.showingRestoreAllAlert = true
                        }) {
                            Text("\(totalOptOutCount)")
                                .font(DSTypography.iconButton)
                                .foregroundColor(Theme.ColorToken.textPrimaryOnDark)
                                .frame(minWidth: 24, minHeight: 24)
                                .background(
                                    Circle()
                                        .fill(Theme.ColorToken.stateWarning)
                                )
                        }
                        .buttonStyle(.plain)
                        .scaleEffect(viewModel.badgeScale)  // Layer 6: Bounce animation
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: viewModel.badgeScale)
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
                        viewModel.toggleCardExpansion(cardType)
                    }
                }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(DSTypography.cardTitle)
                        .foregroundColor(Theme.ColorToken.textSecondaryOnDark)
                }
                .buttonStyle(.plain)
            }
            .padding(DSSpacing.cardPadding)
            .background(Theme.ColorToken.cardHeaderOnDark)

            // Layer 4: Show content only when expanded
            if isExpanded {
                Divider()
                    .background(Theme.ColorToken.dividerOnDark)

                // Card Content
                cardContent(for: cardType)
                    .padding(DSSpacing.cardPadding)
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
                .font(DSTypography.iconButton)
                .foregroundColor(Theme.ColorToken.textSecondaryOnDark)
                .fixedSize(horizontal: false, vertical: true)

            Divider()
                .background(Theme.ColorToken.dividerOnDark)

            // Show goal line toggle
            Toggle(isOn: $showGoalLine) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Show Goal Line on Chart")
                        .font(DSTypography.listTitle)
                        .foregroundColor(Theme.ColorToken.textPrimaryOnDark)
                    Text("Display your target weight on the progress chart")
                        .font(DSTypography.cardCaption)
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
                        .font(DSTypography.iconButton)
                        .foregroundColor(Theme.ColorToken.textSecondaryOnDark)

                    // Compact teal container - matches gold pill size
                    // "150.0" perfectly centered under "Goal Weight" label
                    HStack(spacing: 4) {
                        TextField("Enter goal", text: $viewModel.weightGoalString)
                            .keyboardType(.decimalPad)
                            .font(DSTypography.displayM)
                            .foregroundColor(Theme.ColorToken.textPrimaryOnDark)
                            .multilineTextAlignment(.center)
                            .monospacedDigit()  // Sprint 1: Prevents jitter when digits change
                            .fixedSize()  // Shrink to content width
                            .onChange(of: viewModel.weightGoalString) { _, newValue in
                                // UX/UI Fix #2: Restrict to one decimal place, max 999.9
                                viewModel.formatWeightGoalInput(newValue)
                            }

                        Text("lbs")
                            .font(DSTypography.statValueSmall)
                            .foregroundColor(Theme.ColorToken.textPrimaryOnDark)
                            .accessibilityHidden(true)  // Sprint 1: Avoid redundant "lbs" announcement
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Goal weight \(viewModel.weightGoalString) pounds")
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
                    if let goal = Double(viewModel.weightGoalString),
                       goal > 0,
                       let currentWeight = viewModel.weightManager.latestWeight?.weight {
                        let toGo = currentWeight - goal
                        if toGo > 0 {
                            HStack(spacing: 8) {
                                Image(systemName: "target")
                                    .font(DSTypography.iconButton)
                                    .foregroundColor(Theme.ColorToken.accentGold)
                                Text("\(String(format: "%.1f", toGo)) lbs to go")
                                    .font(DSTypography.cardTitle)
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
            // PHASE 2A: Weight Tracker Daily Reminders
            // Following technical plan: fastlife_notifications_plan.md
            // Simple daily reminder (v1), tone system deferred to v1.1+

            // Benefit copy
            Text("Receive daily reminders for your weigh-in routine.")
                .font(DSTypography.iconButton)
                .foregroundColor(Theme.ColorToken.textSecondaryOnDark)
                .fixedSize(horizontal: false, vertical: true)

            Divider()
                .background(Theme.ColorToken.dividerOnDark)

            // Enable Weight Reminders Toggle
            Toggle(isOn: $viewModel.weightRemindersEnabled) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Enable Weight Reminders")
                        .font(DSTypography.listTitle)
                        .foregroundColor(Theme.ColorToken.textPrimaryOnDark)
                    Text("Get notified at your preferred time each day")
                        .font(DSTypography.cardCaption)
                        .foregroundColor(Theme.ColorToken.textSecondaryOnDark)
                }
            }
            .tint(Theme.ColorToken.accentPrimary)
            .accessibilityLabel("Toggle daily weight reminders")
            .onChange(of: viewModel.weightRemindersEnabled) { _, newValue in
                viewModel.handleReminderToggle(newValue)
            }

            // Settings (only show when enabled)
            if viewModel.weightRemindersEnabled {
                Divider()
                    .background(Theme.ColorToken.dividerOnDark)

                // Timing Mode Picker
                VStack(alignment: .leading, spacing: 8) {
                    Text("Timing")
                        .font(DSTypography.listTitle)
                        .foregroundColor(Theme.ColorToken.textPrimaryOnDark)

                    Picker("Timing Mode", selection: $viewModel.timingMode) {
                        ForEach(WeightControlCenterViewModel.TimingMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .tint(Theme.ColorToken.accentCyan)
                    .onAppear {
                        // Apple's documented approach: Configure UISegmentedControl appearance
                        let appearance = UISegmentedControl.appearance()
                        appearance.setTitleTextAttributes([
                            .foregroundColor: UIColor(Theme.ColorToken.accentCyan)
                        ], for: .normal)
                        appearance.setTitleTextAttributes([
                            .foregroundColor: UIColor.white
                        ], for: .selected)
                    }
                    .onChange(of: viewModel.timingMode) { _, _ in
                        viewModel.saveTimingMode()
                    }
                }

                // Conditional input based on timing mode
                if viewModel.timingMode == .specificTime {
                    // Specific Time: DatePicker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Reminder Time")
                            .font(DSTypography.listTitle)
                            .foregroundColor(Theme.ColorToken.textPrimaryOnDark)

                        DatePicker(
                            "Reminder Time",
                            selection: $viewModel.preferredReminderTime,
                            displayedComponents: .hourAndMinute
                        )
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .colorScheme(.dark)
                        .accessibilityLabel("Set preferred weigh-in reminder time")
                        .onChange(of: viewModel.preferredReminderTime) { _, _ in
                            viewModel.savePreferredTime()
                        }
                    }
                } else {
                    // Before Fasting Goal / After Waking Up: Minutes input
                    VStack(alignment: .leading, spacing: 8) {
                        Text(viewModel.timingMode == .beforeFastingGoal ? "Minutes Before Fasting Goal" : "Minutes After Waking Up")
                            .font(DSTypography.listTitle)
                            .foregroundColor(Theme.ColorToken.textPrimaryOnDark)

                        Stepper(value: $viewModel.minutesOffset, in: 5...120, step: 5) {
                            Text("\(viewModel.minutesOffset) minutes")
                                .font(DSTypography.cardTitle)
                                .foregroundColor(Theme.ColorToken.textPrimaryOnDark)
                        }
                        .onChange(of: viewModel.minutesOffset) { _, _ in
                            viewModel.saveMinutesOffset()
                        }
                    }
                }

                Divider()
                    .background(Theme.ColorToken.dividerOnDark)

                // Quiet Hours Toggle
                Toggle(isOn: $viewModel.quietHoursEnabled) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Quiet Hours")
                            .font(DSTypography.listTitle)
                            .foregroundColor(Theme.ColorToken.textPrimaryOnDark)
                        Text("Don't send reminders during these hours")
                            .font(DSTypography.cardCaption)
                            .foregroundColor(Theme.ColorToken.textSecondaryOnDark)
                    }
                }
                .tint(Theme.ColorToken.accentPrimary)
                .accessibilityLabel("Toggle quiet hours for weight reminders")
                .onChange(of: viewModel.quietHoursEnabled) { _, _ in
                    viewModel.saveQuietHours()
                }

                // Quiet Hours Time Pickers (only show when enabled)
                if viewModel.quietHoursEnabled {
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Start")
                                .font(DSTypography.cardCaption)
                                .foregroundColor(Theme.ColorToken.textSecondaryOnDark)

                            DatePicker(
                                "Quiet Hours Start",
                                selection: $viewModel.quietHoursStart,
                                displayedComponents: .hourAndMinute
                            )
                            .datePickerStyle(.compact)
                            .labelsHidden()
                            .colorScheme(.dark)
                            .accessibilityLabel("Set quiet hours start time")
                            .onChange(of: viewModel.quietHoursStart) { _, _ in
                                viewModel.saveQuietHours()
                            }
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("End")
                                .font(DSTypography.cardCaption)
                                .foregroundColor(Theme.ColorToken.textSecondaryOnDark)

                            DatePicker(
                                "Quiet Hours End",
                                selection: $viewModel.quietHoursEnd,
                                displayedComponents: .hourAndMinute
                            )
                            .datePickerStyle(.compact)
                            .labelsHidden()
                            .colorScheme(.dark)
                            .accessibilityLabel("Set quiet hours end time")
                            .onChange(of: viewModel.quietHoursEnd) { _, _ in
                                viewModel.saveQuietHours()
                            }
                        }
                    }
                }

                Divider()
                    .background(Theme.ColorToken.dividerOnDark)

                // Skip Days Disclosure Group
                DisclosureGroup("Skip Days") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Don't send reminders on these days")
                            .font(DSTypography.cardCaption)
                            .foregroundColor(Theme.ColorToken.textSecondaryOnDark)
                            .padding(.bottom, 4)

                        ForEach(viewModel.weekdays, id: \.number) { day in
                            Toggle(isOn: Binding(
                                get: { viewModel.skipWeekdays.contains(day.number) },
                                set: { isSkipped in
                                    if isSkipped {
                                        viewModel.skipWeekdays.insert(day.number)
                                    } else {
                                        viewModel.skipWeekdays.remove(day.number)
                                    }
                                    viewModel.saveSkipWeekdays()
                                }
                            )) {
                                Text(day.name)
                                    .font(DSTypography.labelSecondary)
                                    .foregroundColor(Theme.ColorToken.textPrimaryOnDark)
                            }
                            .tint(Theme.ColorToken.accentPrimary)
                            .accessibilityLabel("Skip weight reminders on \(day.name)")
                        }
                    }
                    .padding(.top, 8)
                }
                .font(DSTypography.listTitle)
                .foregroundColor(Theme.ColorToken.textPrimaryOnDark)
                .accentColor(Theme.ColorToken.textPrimaryOnDark)
            }

            // MARK: - Additional Notification Types (Phase 2a enhancement)

            Divider()
                .background(Theme.ColorToken.dividerOnDark)

            // "Did You Know" Toggle
            Toggle(isOn: $viewModel.didYouKnowEnabled) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Did You Know")
                        .font(DSTypography.listTitle)
                        .foregroundColor(Theme.ColorToken.textPrimaryOnDark)
                    Text("Educational facts about weight tracking")
                        .font(DSTypography.cardCaption)
                        .foregroundColor(Theme.ColorToken.textSecondaryOnDark)
                }
            }
            .tint(Theme.ColorToken.accentPrimary)
            .onChange(of: viewModel.didYouKnowEnabled) { _, _ in
                viewModel.saveDidYouKnowSettings()
            }

            // Frequency picker (only show when enabled)
            if viewModel.didYouKnowEnabled {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Frequency")
                        .font(DSTypography.cardCaption)
                        .foregroundColor(Theme.ColorToken.textSecondaryOnDark)

                    Picker("Frequency", selection: $viewModel.didYouKnowFrequency) {
                        ForEach(WeightControlCenterViewModel.NotificationFrequency.allCases, id: \.self) { frequency in
                            Text(frequency.rawValue).tag(frequency)
                        }
                    }
                    .pickerStyle(.segmented)
                    .tint(Theme.ColorToken.accentCyan)
                    .onChange(of: viewModel.didYouKnowFrequency) { _, _ in
                        viewModel.saveDidYouKnowSettings()
                    }
                }
            }

            Divider()
                .background(Theme.ColorToken.dividerOnDark)

            // "Motivational" Toggle
            Toggle(isOn: $viewModel.motivationalEnabled) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Motivational")
                        .font(DSTypography.listTitle)
                        .foregroundColor(Theme.ColorToken.textPrimaryOnDark)
                    Text("Encouragement messages to keep you going")
                        .font(DSTypography.cardCaption)
                        .foregroundColor(Theme.ColorToken.textSecondaryOnDark)
                }
            }
            .tint(Theme.ColorToken.accentPrimary)
            .onChange(of: viewModel.motivationalEnabled) { _, _ in
                viewModel.saveMotivationalSettings()
            }

            // Frequency picker (only show when enabled)
            if viewModel.motivationalEnabled {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Frequency")
                        .font(DSTypography.cardCaption)
                        .foregroundColor(Theme.ColorToken.textSecondaryOnDark)

                    Picker("Frequency", selection: $viewModel.motivationalFrequency) {
                        ForEach(WeightControlCenterViewModel.NotificationFrequency.allCases, id: \.self) { frequency in
                            Text(frequency.rawValue).tag(frequency)
                        }
                    }
                    .pickerStyle(.segmented)
                    .tint(Theme.ColorToken.accentCyan)
                    .onChange(of: viewModel.motivationalFrequency) { _, _ in
                        viewModel.saveMotivationalSettings()
                    }
                }
            }

            Divider()
                .background(Theme.ColorToken.dividerOnDark)

            // "Action Steps" Toggle
            Toggle(isOn: $viewModel.actionStepsEnabled) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Action Steps")
                        .font(DSTypography.listTitle)
                        .foregroundColor(Theme.ColorToken.textPrimaryOnDark)
                    Text("Practical tips and habit-building steps")
                        .font(DSTypography.cardCaption)
                        .foregroundColor(Theme.ColorToken.textSecondaryOnDark)
                }
            }
            .tint(Theme.ColorToken.accentPrimary)
            .onChange(of: viewModel.actionStepsEnabled) { _, _ in
                viewModel.saveActionStepsSettings()
            }

            // Frequency picker (only show when enabled)
            if viewModel.actionStepsEnabled {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Frequency")
                        .font(DSTypography.cardCaption)
                        .foregroundColor(Theme.ColorToken.textSecondaryOnDark)

                    Picker("Frequency", selection: $viewModel.actionStepsFrequency) {
                        ForEach(WeightControlCenterViewModel.NotificationFrequency.allCases, id: \.self) { frequency in
                            Text(frequency.rawValue).tag(frequency)
                        }
                    }
                    .pickerStyle(.segmented)
                    .tint(Theme.ColorToken.accentCyan)
                    .onChange(of: viewModel.actionStepsFrequency) { _, _ in
                        viewModel.saveActionStepsSettings()
                    }
                }
            }
        }
    }

    // MARK: - Insights Card

    private var insightsCardContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Sprint 1: Remove "coming soon" vaporware feel
            Text("Smart tips based on your trends.")
                .font(DSTypography.listTitle)
                .foregroundColor(Theme.ColorToken.textSecondaryOnDark)

            // TODO: Add contextual micro-lessons
            // Reference: FAST-LIFe_Control_Center_Vision.md §D
        }
    }

    // MARK: - Sync Card

    private var syncCardContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Sync toggle
            Toggle(isOn: $viewModel.localSyncEnabled) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Sync with Apple Health")
                        .font(DSTypography.listTitle)
                        .foregroundColor(Theme.ColorToken.textPrimaryOnDark)
                    // Sprint 1: Benefit copy - multi-line format (1 sentence per line)
                    Text("Auto-import your weight from Apple Health.")
                        .font(DSTypography.cardCaption)
                        .foregroundColor(Theme.ColorToken.textSecondaryOnDark)
                    Text("No manual entry.")
                        .font(DSTypography.cardCaption)
                        .foregroundColor(Theme.ColorToken.textSecondaryOnDark)
                    Text(viewModel.hasHealthKitPermission ? "Ready to sync" : "Not synced")
                        .font(DSTypography.listCaption)
                        .foregroundColor(viewModel.hasHealthKitPermission ? Theme.ColorToken.accentPrimary : Theme.ColorToken.textSecondaryOnDark)
                }
            }
            .tint(Theme.ColorToken.accentPrimary)
            .disabled(!viewModel.canEnableSync)
            .onChange(of: viewModel.localSyncEnabled) { _, newValue in
                viewModel.userSyncPreference = newValue
                if viewModel.canEnableSync {
                    viewModel.weightManager.setSyncPreference(newValue)
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    viewModel.updatePermissionStatus()
                    viewModel.updateToggleState()
                }
            }

            if viewModel.localSyncEnabled {
                Divider()
                    .background(Theme.ColorToken.dividerOnDark)

                // Sync button
                Button(action: {
                    viewModel.syncWithHealthKit()
                }) {
                    HStack(spacing: 8) {
                        if viewModel.isSyncing {
                            ProgressView()
                                .tint(Theme.ColorToken.textPrimaryOnDark)
                        } else {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(DSTypography.cardTitle)
                        }
                        Text(viewModel.isSyncing ? "Syncing..." : "Sync Now")
                            .font(DSTypography.cardTitle)
                    }
                    .foregroundColor(Theme.ColorToken.textPrimaryOnDark)
                    .frame(maxWidth: .infinity)
                    .padding(DSSpacing.cardElementSpacing)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Theme.ColorToken.accentPrimary)
                    )
                }
                .disabled(viewModel.isSyncing || !viewModel.hasHealthKitPermission)
                .opacity((viewModel.isSyncing || !viewModel.hasHealthKitPermission) ? 0.5 : 1.0)
            }

            // Status message
            if !viewModel.hasHealthKitPermission {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(Theme.ColorToken.stateWarning)
                    Text(viewModel.permissionStatusMessage)
                        .font(DSTypography.cardCaption)
                        .foregroundColor(Theme.ColorToken.textSecondaryOnDark)
                }
            } else if !viewModel.lastSyncStatus.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Theme.ColorToken.accentPrimary)
                    Text(viewModel.lastSyncStatus)
                        .font(DSTypography.cardCaption)
                        .foregroundColor(Theme.ColorToken.textSecondaryOnDark)
                }
            }

            // Behavioral insight: Trust badge
            // Issue #4: Centered horizontally
            if viewModel.hasHealthKitPermission && viewModel.localSyncEnabled {
                HStack(spacing: 8) {
                    Image(systemName: "lock.shield.fill")
                        .foregroundColor(Theme.ColorToken.accentInfo)
                        .font(DSTypography.listCaption)
                    Text("Your data is secure & up-to-date")
                        .font(DSTypography.statLabel)
                        .foregroundColor(Theme.ColorToken.textSecondaryOnDark)
                }
                .padding(DSSpacing.cardSmallSpacing)
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
                .font(DSTypography.listTitle)
                .foregroundColor(Theme.ColorToken.textSecondaryOnDark)

            // Show weight history list (reusing existing component)
            WeightHistoryListView(weightManager: viewModel.weightManager)
        }
    }

    // MARK: - Manage My Experience Card

    private var experienceCardContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Subtitle: Purpose of this card
            Text("Control which tips, nudges, and summaries you see (Opt-outs live here).")
                .font(DSTypography.iconButton)
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
                    get: { !viewModel.optOutEducationalInsights },
                    set: { viewModel.optOutEducationalInsights = !$0; viewModel.saveExperienceOptOuts() }
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
                    get: { !viewModel.optOutBehavioralNudges },
                    set: { viewModel.optOutBehavioralNudges = !$0; viewModel.saveExperienceOptOuts() }
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
                    get: { !viewModel.optOutMotivationalMessages },
                    set: { viewModel.optOutMotivationalMessages = !$0; viewModel.saveExperienceOptOuts() }
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
            if viewModel.shouldShowRestoreButton {
                Divider()
                    .background(Theme.ColorToken.dividerOnDark)

                Button(action: {
                    // Show confirmation alert (same behavior as badge)
                    viewModel.showingRestoreAllAlert = true
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.clockwise")
                            .font(DSTypography.cardTitle)
                        Text("Restore All")
                            .font(DSTypography.cardTitle)
                    }
                    .foregroundColor(Theme.ColorToken.textPrimaryOnDark)
                    .frame(maxWidth: .infinity)
                    .padding(DSSpacing.cardElementSpacing)
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
                        .font(DSTypography.listTitle)
                        .foregroundColor(Theme.ColorToken.textPrimaryOnDark)
                    Text(description)
                        .font(DSTypography.cardCaption)
                        .foregroundColor(Theme.ColorToken.textSecondaryOnDark)
                }
            }
            .tint(Theme.ColorToken.accentPrimary)

            // Show individual opted-out items for this category (if any)
            let optedOutItems = viewModel.optOutManager.optedOutContentItems.filter { $0.category == category }
            if !optedOutItems.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    // "Individual opt-outs" header
                    Text("Individual opt-outs:")
                        .font(DSTypography.statLabel)
                        .foregroundColor(Theme.ColorToken.textSecondaryOnDark.opacity(0.7))
                        .padding(.leading, 16)
                        .padding(.top, 4)

                    // List of opted-out items
                    // Layer 3: Each item has .id() for ScrollViewReader targeting
                    ForEach(Array(optedOutItems.enumerated()), id: \.element.id) { index, item in
                        let isHighlighted = viewModel.highlightedItemID == item.id

                        HStack(spacing: 8) {
                            Image(systemName: "minus.circle.fill")
                                .font(DSTypography.cardSubtitle)
                                .foregroundColor(Theme.ColorToken.stateWarning)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.displayText)
                                    .font(DSTypography.labelSecondary)
                                    .foregroundColor(Theme.ColorToken.textPrimaryOnDark)
                                Text("Opted out \(item.timestamp.formatted(date: .abbreviated, time: .omitted))")
                                    .font(DSTypography.pillLabel)
                                    .foregroundColor(Theme.ColorToken.textSecondaryOnDark.opacity(0.6))
                            }

                            Spacer()

                            // Restore button for individual item
                            Button(action: {
                                viewModel.optOutManager.optInContent(id: item.id)
                            }) {
                                Text("Restore")
                                    .font(DSTypography.statLabel)
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
                    TrackerCardType.allCases.allSatisfy { viewModel.cardManager.isCardVisible($0) }
                },
                set: { newValue in
                    // When toggle changes: Show or hide ALL 5 cards
                    for cardType in TrackerCardType.allCases {
                        if newValue {
                            viewModel.cardManager.showCard(cardType)
                        } else {
                            viewModel.cardManager.hideCard(cardType)
                        }
                    }
                    // Also update legacy @AppStorage flag (for backwards compatibility)
                    viewModel.optOutTrackerCards = !newValue
                    viewModel.saveExperienceOptOuts()
                }
            )) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Weight Tracker Cards")
                        .font(DSTypography.listTitle)
                        .foregroundColor(Theme.ColorToken.textPrimaryOnDark)
                    Text("Manage which cards appear on your tracker")
                        .font(DSTypography.cardCaption)
                        .foregroundColor(Theme.ColorToken.textSecondaryOnDark)
                }
            }
            .tint(Theme.ColorToken.accentPrimary)

            // Show hidden tracker cards (if any) - via TrackerCardManager (Single Source of Truth)
            let hiddenCards = TrackerCardType.allCases.filter { cardType in
                !viewModel.cardManager.isCardVisible(cardType)
            }

            if !hiddenCards.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    // "Hidden cards" header
                    Text("Hidden cards:")
                        .font(DSTypography.statLabel)
                        .foregroundColor(Theme.ColorToken.textSecondaryOnDark.opacity(0.7))
                        .padding(.leading, 16)
                        .padding(.top, 4)

                    // List of hidden cards
                    ForEach(hiddenCards) { cardType in
                        HStack(spacing: 8) {
                            Image(systemName: "eye.slash.fill")
                                .font(DSTypography.cardSubtitle)
                                .foregroundColor(Theme.ColorToken.stateWarning)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(cardType.displayName)
                                    .font(DSTypography.labelSecondary)
                                    .foregroundColor(Theme.ColorToken.textPrimaryOnDark)
                                Text(cardType.description)
                                    .font(DSTypography.pillLabel)
                                    .foregroundColor(Theme.ColorToken.textSecondaryOnDark.opacity(0.6))
                            }

                            Spacer()

                            // Restore button for individual card (via TrackerCardManager)
                            Button(action: {
                                viewModel.cardManager.showCard(cardType)
                            }) {
                                Text("Restore")
                                    .font(DSTypography.statLabel)
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
                    ProgressStoryCardType.allCases.allSatisfy { viewModel.progressStoryCardManager.isCardVisible($0) }
                },
                set: { newValue in
                    // When toggle changes: Show or hide ALL 5 Progress Story cards
                    for cardType in ProgressStoryCardType.allCases {
                        if newValue {
                            viewModel.progressStoryCardManager.showCard(cardType)
                        } else {
                            viewModel.progressStoryCardManager.hideCard(cardType)
                        }
                    }
                    // Also update legacy @AppStorage flag (for backwards compatibility)
                    viewModel.optOutProgressSummaries = !newValue
                    viewModel.saveExperienceOptOuts()
                }
            )) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your Progress Journey")
                        .font(DSTypography.listTitle)
                        .foregroundColor(Theme.ColorToken.textPrimaryOnDark)
                    Text("Weekly recaps showing trends and wins")
                        .font(DSTypography.cardCaption)
                        .foregroundColor(Theme.ColorToken.textSecondaryOnDark)
                }
            }
            .tint(Theme.ColorToken.accentPrimary)

            // Show hidden Progress Story cards (if any) - via ProgressStoryCardManager (Single Source of Truth)
            let hiddenCards = ProgressStoryCardType.allCases.filter { cardType in
                !viewModel.progressStoryCardManager.isCardVisible(cardType)
            }

            if !hiddenCards.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    // "Hidden cards" header
                    Text("Hidden cards:")
                        .font(DSTypography.statLabel)
                        .foregroundColor(Theme.ColorToken.textSecondaryOnDark.opacity(0.7))
                        .padding(.leading, 16)
                        .padding(.top, 4)

                    // List of hidden Progress Story cards
                    ForEach(hiddenCards) { cardType in
                        HStack(spacing: 8) {
                            Image(systemName: "eye.slash.fill")
                                .font(DSTypography.cardSubtitle)
                                .foregroundColor(Theme.ColorToken.stateWarning)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(cardType.displayName)
                                    .font(DSTypography.labelSecondary)
                                    .foregroundColor(Theme.ColorToken.textPrimaryOnDark)
                                Text(cardType.description)
                                    .font(DSTypography.pillLabel)
                                    .foregroundColor(Theme.ColorToken.textSecondaryOnDark.opacity(0.6))
                            }

                            Spacer()

                            // Restore button for individual card (via ProgressStoryCardManager)
                            Button(action: {
                                viewModel.progressStoryCardManager.showCard(cardType)
                            }) {
                                Text("Restore")
                                    .font(DSTypography.statLabel)
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

    // REMOVED: restoreAllToDefault - now in ViewModel
    // All restore functionality moved to viewModel.restoreAllToDefault()

    // MARK: - About Card (Fixed at Bottom)

    private var aboutCard: some View {
        let isExpanded = viewModel.expandedCards.contains("about")

        return VStack(spacing: 0) {
            // Card Header
            HStack(spacing: 12) {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(Theme.ColorToken.accentInfo)
                    .font(DSTypography.displayS)

                Text("About")
                    .font(DSTypography.displaySRounded)
                    .foregroundColor(Theme.ColorToken.textPrimaryOnDark)

                Spacer()

                // Layer 4: Chevron expand/collapse button
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        if viewModel.expandedCards.contains("about") {
                            viewModel.expandedCards.remove("about")
                        } else {
                            viewModel.expandedCards.insert("about")
                        }
                        viewModel.saveExpandedCards()
                    }
                }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(DSTypography.cardTitle)
                        .foregroundColor(Theme.ColorToken.textSecondaryOnDark)
                }
                .buttonStyle(.plain)
            }
            .padding(DSSpacing.cardPadding)
            .background(Theme.ColorToken.cardHeaderOnDark)

            // Layer 4: Show content only when expanded
            if isExpanded {
                Divider()
                    .background(Theme.ColorToken.dividerOnDark)

                // About content
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Total Entries")
                            .font(DSTypography.listTitle)
                            .foregroundColor(Theme.ColorToken.textSecondaryOnDark)
                        Spacer()
                        Text("\(viewModel.weightManager.weightEntries.count)")
                            .font(DSTypography.cardTitle)
                            .foregroundColor(Theme.ColorToken.textPrimaryOnDark)
                    }

                    // Behavioral insight: Identity reinforcement
                    if let oldest = viewModel.weightManager.weightEntries.sorted(by: { $0.date < $1.date }).first {
                        Divider()
                            .background(Theme.ColorToken.dividerOnDark)

                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Tracking Since")
                                    .font(DSTypography.listTitle)
                                    .foregroundColor(Theme.ColorToken.textSecondaryOnDark)
                                Spacer()
                                Text(oldest.date.formatted(date: .abbreviated, time: .omitted))
                                    .font(DSTypography.cardTitle)
                                    .foregroundColor(Theme.ColorToken.textPrimaryOnDark)
                            }

                            // Identity badge
                            HStack(spacing: 6) {
                                Image(systemName: "star.fill")
                                    .font(DSTypography.pillLabel)
                                    .foregroundColor(Theme.ColorToken.accentGold)
                                Text("You've logged \(viewModel.weightManager.weightEntries.count) entries since \(Calendar.current.component(.year, from: oldest.date))")
                                    .font(DSTypography.statLabel)
                                    .foregroundColor(Theme.ColorToken.textSecondaryOnDark)
                            }
                            .padding(.top, 4)
                        }
                    }
                }
                .padding(DSSpacing.cardPadding)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Theme.ColorToken.cardOnDark)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Theme.ColorToken.shadowCardOnDark, radius: 16, x: 0, y: 8)
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
