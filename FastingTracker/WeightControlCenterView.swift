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
        case .progressSummaries: return "Progress Summaries"
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
    case experience = "experience"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .goals: return "Goals"
        case .notifications: return "Notifications"
        case .insights: return "Insights & Education"
        case .sync: return "Apple Health Sync"
        case .experience: return "Manage My Experience"
        }
    }

    var icon: String {
        switch self {
        case .goals: return "flag.fill"
        case .notifications: return "bell.fill"
        case .insights: return "lightbulb.fill"
        case .sync: return "arrow.triangle.2.circlepath"
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

    // Card order persistence - default: Goals → Notifications → Insights → Sync → Experience
    @AppStorage("weightControlCenterCardOrder") private var cardOrderData: Data = Data()
    @State private var cardOrder: [ControlCenterCardType] = [.goals, .notifications, .insights, .sync, .experience]

    // Drag and drop state (Hub pattern)
    @State private var draggedCard: ControlCenterCardType?

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
                ScrollView {
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
    }

    // MARK: - Card Views

    @ViewBuilder
    private func cardView(for cardType: ControlCenterCardType) -> some View {
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

                // Badge for Manage My Experience card showing count of opted-out categories + items
                if cardType == .experience {
                    let categoryOptOutCount = [optOutEducationalInsights, optOutBehavioralNudges, optOutMotivationalMessages, optOutProgressSummaries].filter({ $0 }).count
                    let individualOptOutCount = optOutManager.optedOutContentItems.count
                    let totalOptOutCount = categoryOptOutCount + individualOptOutCount

                    if totalOptOutCount > 0 {
                        Text("\(totalOptOutCount)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Theme.ColorToken.textPrimaryOnDark)
                            .frame(minWidth: 24, minHeight: 24)
                            .background(
                                Circle()
                                    .fill(Theme.ColorToken.stateWarning)
                            )
                            .accessibilityLabel("\(totalOptOutCount) \(totalOptOutCount == 1 ? "item" : "items") opted out")
                    }
                }
            }
            .padding(16)
            .background(Theme.ColorToken.cardHeaderOnDark)

            Divider()
                .background(Theme.ColorToken.dividerOnDark)

            // Card Content
            cardContent(for: cardType)
                .padding(16)
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

            // Progress Summaries Toggle (Category-level control)
            categoryToggle(
                isOn: Binding(
                    get: { !self.optOutProgressSummaries },
                    set: { self.optOutProgressSummaries = !$0 }
                ),
                title: "Progress Summaries",
                description: "Weekly recaps showing trends and wins",
                category: .progressSummaries
            )

            // Restore All button (only show if at least one category is paused)
            if optOutEducationalInsights || optOutBehavioralNudges || optOutMotivationalMessages || optOutProgressSummaries {
                Divider()
                    .background(Theme.ColorToken.dividerOnDark)

                Button(action: {
                    // Restore all categories (turn all back on by setting all opt-outs to false)
                    optOutEducationalInsights = false
                    optOutBehavioralNudges = false
                    optOutMotivationalMessages = false
                    optOutProgressSummaries = false
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
                    ForEach(optedOutItems) { item in
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
                        .padding(.horizontal, 8)
                    }
                }
            }
        }
    }

    // MARK: - About Card (Fixed at Bottom)

    private var aboutCard: some View {
        VStack(spacing: 0) {
            // Card Header
            HStack(spacing: 12) {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(Theme.ColorToken.accentInfo)
                    .font(.system(size: 20, weight: .semibold))

                Text("About")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Theme.ColorToken.textPrimaryOnDark)

                Spacer()
            }
            .padding(16)
            .background(Theme.ColorToken.cardHeaderOnDark)

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
        }
        .background(Theme.ColorToken.cardOnDark)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Theme.ColorToken.shadowCardOnDark, radius: 16, x: 0, y: 8)
    }

    // MARK: - Card Order Persistence

    private func loadCardOrder() {
        if let decoded = try? JSONDecoder().decode([ControlCenterCardType].self, from: cardOrderData) {
            // Migration: Add .experience card if it's missing from saved order
            if !decoded.contains(.experience) {
                // Append Experience card to end of existing order
                cardOrder = decoded + [.experience]
                // Save the migrated order
                saveCardOrder()
            } else {
                cardOrder = decoded
            }
        } else {
            // Default order: Goals → Notifications → Insights → Sync → Experience
            cardOrder = [.goals, .notifications, .insights, .sync, .experience]
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
