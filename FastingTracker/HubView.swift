import SwiftUI

/// HubView - Central dashboard displaying all tracker summaries
/// Following Apple SwiftUI MVVM patterns and HIG guidelines for tab-based navigation
/// Reference: https://developer.apple.com/design/human-interface-guidelines/tab-bars
struct HubView: View {
    // MARK: - Environment Objects (Following shared instance pattern like FastingManager)
    @EnvironmentObject var fastingManager: FastingManager
    @EnvironmentObject var hydrationManager: HydrationManager
    @StateObject private var weightManager = WeightManager()
    @StateObject private var sleepManager = SleepManager()
    @StateObject private var moodManager = MoodManager()
    // Note: Mood tracker handles both mood and energy data

    // MARK: - Navigation State Management (Following AdvancedView pattern)
    // Industry Standard: Tab-driven navigation reset for "home" functionality
    @Binding var shouldPopToRoot: Bool
    @State private var navigationPath = NavigationPath()

    // MARK: - State Management (Apple SwiftUI Guidelines)
    @AppStorage("hubTrackerOrder") private var trackerOrderData: Data = Data()
    @State private var trackerOrder: [TrackerType] = [.weight, .fasting, .sleep, .hydration, .mood]
    @State private var draggedTracker: TrackerType?

    // MARK: - Main Content View (Decomposed for Compilation Performance)
    @ViewBuilder
    private var mainContentView: some View {
        // Industry standard: GeometryReader for proper vertical centering in tab-based apps
        // Following Apple Health, Instagram, Twitter content centering patterns
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
                    // MARK: - Luxury Navigation Title (Centered Premium Design)
                    luxuryNavigationTitle

                    // MARK: - Top Status Bar (Heart Rate - Luxury Spec Section 2)
                    TopStatusBar()

                    // MARK: - Vertically Centered Content Area
                    trackerCardsSection(geometry: geometry)
                }
            }
        }
    }

    // MARK: - Luxury Background Gradient
    @ViewBuilder
    private var luxuryBackgroundGradient: some View {
        LinearGradient(
            colors: [
                Color(hex: "#0D1B2A"),     // background.dark
                Color(hex: "#0B1020")      // background.gradient end
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    // MARK: - Tracker Cards Section
    @ViewBuilder
    private func trackerCardsSection(geometry: GeometryProxy) -> some View {
        VStack(spacing: 0) {
            // MARK: - Tracker List (5 trackers in full-width layout)
            LazyVStack(spacing: 12) {
                ForEach(trackerOrder, id: \.self) { tracker in
                    TrackerSummaryCard(
                        tracker: tracker,
                        trackerOrder: trackerOrder,
                        weightManager: weightManager,
                        hydrationManager: hydrationManager,
                        sleepManager: sleepManager,
                        moodManager: moodManager
                    )
                        .onDrag {
                            // SwiftUI Drag & Drop API - Long press to drag, tap to navigate
                            // Reference: https://developer.apple.com/documentation/swiftui/view/ondrag(_:)
                            self.draggedTracker = tracker
                            return NSItemProvider(object: tracker.rawValue as NSString)
                        }
                        .onDrop(of: [.text], delegate: TrackerDropDelegate(
                            tracker: tracker,
                            trackerOrder: $trackerOrder,
                            draggedTracker: $draggedTracker
                        ))
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
        }
        .frame(minHeight: geometry.size.height - 150) // Reduced to move content up
        .frame(maxWidth: .infinity)
        .clipped()
    }

    // MARK: - Luxury Navigation Title Component
    // Following industry standards: Tesla app, Apple Watch, Nike Training Club
    // Centered white typography for premium dashboard experience
    @ViewBuilder
    private var luxuryNavigationTitle: some View {
        VStack(spacing: 0) {
            // Luxury title with proper spacing and typography
            HStack {
                Spacer()

                Text("Hub")
                    .font(.system(size: 34, weight: .bold, design: .default))
                    .foregroundColor(.white)
                    .kerning(0.5) // Luxury typography spacing

                Spacer()
            }
            .padding(.top, 4)
            .padding(.bottom, 8)
            .background(
                // Subtle background extension for visual hierarchy
                LinearGradient(
                    colors: [
                        Color(hex: "#0D1B2A").opacity(0.95),
                        Color(hex: "#0D1B2A").opacity(0.85)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            mainContentView
                .background(luxuryBackgroundGradient)
                .navigationBarHidden(true)
        }
        .onAppear {
            loadTrackerOrder()
        }
        .onChange(of: trackerOrder) { _, newOrder in
            saveTrackerOrder(newOrder)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            // Following Apple reactive UI patterns - refresh data when app becomes active
            // This ensures real-time updates when returning from other apps
        }
        .onChange(of: shouldPopToRoot) { _, newValue in
            // Industry Standard: Tab-driven navigation reset following AdvancedView pattern
            // Reference: Apple HIG - "Tapping a currently selected tab should return to the top-level view"
            if newValue {
                navigationPath = NavigationPath()
                shouldPopToRoot = false
            }
        }
    }

    // MARK: - Tracker Order Persistence (UserDefaults pattern from HANDOFF.md)
    private func loadTrackerOrder() {
        guard let orderStrings = try? JSONDecoder().decode([String].self, from: trackerOrderData) else {
            return // Use default order
        }
        let loadedOrder = orderStrings.compactMap { TrackerType(rawValue: $0) }
        if loadedOrder.count == 5 { // Ensure all trackers are present
            trackerOrder = loadedOrder
        }
    }

    private func saveTrackerOrder(_ order: [TrackerType]) {
        let orderStrings = order.map { $0.rawValue }
        if let data = try? JSONEncoder().encode(orderStrings) {
            trackerOrderData = data
        }
    }
}

// TrackerType enum imported from AppSettings.swift (centralized type definition)

// MARK: - Drag & Drop Delegate (Apple SwiftUI Drag/Drop API)
// Reference: https://developer.apple.com/documentation/swiftui/dropdelegate
struct TrackerDropDelegate: DropDelegate {
    let tracker: TrackerType
    @Binding var trackerOrder: [TrackerType]
    @Binding var draggedTracker: TrackerType?

    func performDrop(info: DropInfo) -> Bool {
        guard let draggedTracker = draggedTracker else { return false }

        // Reorder logic following Apple's drag/drop patterns
        if let fromIndex = trackerOrder.firstIndex(of: draggedTracker),
           let toIndex = trackerOrder.firstIndex(of: tracker) {

            withAnimation(.spring()) {
                trackerOrder.move(fromOffsets: IndexSet(integer: fromIndex), toOffset: toIndex > fromIndex ? toIndex + 1 : toIndex)
            }
        }

        self.draggedTracker = nil
        return true
    }

    func dropEntered(info: DropInfo) {
        // Optional: Add visual feedback during drag
    }

    func dropExited(info: DropInfo) {
        // Optional: Remove visual feedback
    }
}

// MARK: - TrackerSummaryCard (Navy-themed design)
struct TrackerSummaryCard: View {
    let tracker: TrackerType
    let trackerOrder: [TrackerType]
    @EnvironmentObject var fastingManager: FastingManager

    // Industry standard: Use @ObservedObject for SwiftUI reactivity to @Published properties
    // Reference: https://developer.apple.com/documentation/swiftui/observedobject
    @ObservedObject var weightManager: WeightManager
    @ObservedObject var hydrationManager: HydrationManager
    @ObservedObject var sleepManager: SleepManager
    @ObservedObject var moodManager: MoodManager

    // Date formatter for consistent date display
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }

    // Computed property for fasting display value following ContentView patterns
    private var fastingDisplayValue: String {
        switch tracker {
        case .fasting:
            if fastingManager.isActive {
                // Show current fasting time (same format as ContentView)
                let hours = Int(fastingManager.elapsedTime) / 3600
                let minutes = Int(fastingManager.elapsedTime) / 60 % 60
                let seconds = Int(fastingManager.elapsedTime) % 60
                return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
            } else {
                // Show time since last fast (matching original enhanced display format)
                if let lastFast = fastingManager.fastingHistory.first,
                   let lastEndTime = lastFast.endTime {
                    let timeSince = Date().timeIntervalSince(lastEndTime)
                    let hours = Int(timeSince) / 3600
                    let minutes = Int(timeSince) / 60 % 60

                    if hours > 24 {
                        let days = hours / 24
                        return "\(days)d ago"
                    } else if hours > 0 {
                        return "\(hours)h \(minutes)m ago"
                    } else {
                        return "\(minutes)m ago"
                    }
                } else {
                    return "No fasts yet"
                }
            }
        default:
            return "Current Value"
        }
    }

    // Computed property for 7-day average fasting time
    private var averageFastingTime: String {
        let last7Days = fastingManager.fastingHistory.prefix(7)
        let completedFasts = last7Days.filter { $0.endTime != nil }

        guard !completedFasts.isEmpty else {
            return "-- hrs"
        }

        let totalDuration = completedFasts.reduce(0) { result, session in
            guard let endTime = session.endTime else { return result }
            return result + endTime.timeIntervalSince(session.startTime)
        }

        let averageDuration = totalDuration / Double(completedFasts.count)
        let hours = Int(averageDuration) / 3600
        let minutes = Int(averageDuration) / 60 % 60

        return String(format: "%02d:%02d", hours, minutes)
    }

    // Computed property for goal end time
    private var goalEndTime: String {
        if fastingManager.isActive, let startTime = fastingManager.currentSession?.startTime {
            let goalDuration = fastingManager.fastingGoalHours * 3600
            let endTime = startTime.addingTimeInterval(goalDuration)

            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return formatter.string(from: endTime)
        } else if let lastFast = fastingManager.fastingHistory.first,
                  let lastEndTime = lastFast.endTime {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return formatter.string(from: lastEndTime)
        } else {
            return "-- --"
        }
    }

    @ViewBuilder
    private var destinationView: some View {
        switch tracker {
        case .fasting:
            // Use existing ContentView for fasting (preserve working functionality)
            ContentView()
        case .weight:
            WeightTrackingView()
        case .hydration:
            HydrationTrackingView()
        case .sleep:
            SleepTrackingView()
        case .mood:
            MoodTrackingView()
        }
    }

    var body: some View {
        // Conditional navigation: Fasting tracker has individual interactive elements
        Group {
            if tracker == .fasting {
                // Fasting tracker: Background navigation + individual interactive elements
                NavigationLink(destination: destinationView) {
                    cardContent
                }
                .buttonStyle(.plain)
            } else {
                // Other trackers: Whole card is clickable
                NavigationLink(destination: destinationView) {
                    cardContent
                }
            }
        }
    }

    @ViewBuilder
    private var cardContent: some View {
        HStack(spacing: 20) {
            // Tracker info section
            VStack(alignment: .leading, spacing: 6) {
                // Tracker title and values
                HStack(spacing: 12) {
                    // Icon positioned next to title
                    Image(systemName: tracker.icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.white)

                    Text(tracker.displayName)
                        .font(.system(.title2, design: .rounded, weight: .semibold))
                        .foregroundColor(.white)

                    Spacer()

                    // Values positioned on right side within HStack
                    if tracker != trackerOrder.first {
                        // Non-featured tracker values
                        if tracker == .fasting {
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(fastingManager.isActive ? "Time Since Fast Started" : "Time Since Last Fast")
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.7))
                                Text(simpleDisplayValue(for: tracker))
                                    .font(.system(.title3, design: .rounded, weight: .semibold))
                                    .foregroundColor(Color("FLWarning"))
                            }
                        } else if tracker == .mood {
                            VStack(alignment: .trailing, spacing: 2) {
                                if let avgMood = moodManager.todayAverageMood,
                                   let avgEnergy = moodManager.todayAverageEnergy {
                                    Text("\(String(format: "%.1f", avgMood)) m")
                                        .font(.system(.title3, design: .rounded, weight: .semibold))
                                        .foregroundColor(Color("FLWarning"))
                                    Text("\(String(format: "%.1f", avgEnergy)) e")
                                        .font(.system(.title3, design: .rounded, weight: .semibold))
                                        .foregroundColor(Color("FLWarning"))
                                } else {
                                    Text("-- m")
                                        .font(.system(.title3, design: .rounded, weight: .semibold))
                                        .foregroundColor(Color("FLWarning"))
                                    Text("-- e")
                                        .font(.system(.title3, design: .rounded, weight: .semibold))
                                        .foregroundColor(Color("FLWarning"))
                                }
                            }
                        } else {
                            Text(simpleDisplayValue(for: tracker))
                                .font(.system(.title3, design: .rounded, weight: .semibold))
                                .foregroundColor(Color("FLWarning"))
                                .multilineTextAlignment(.trailing)
                        }
                    } else {
                        // Featured tracker - interactive fasting time
                        if tracker == .fasting {
                            fastingTimeNavigation
                        }
                    }
                }

                // Enhanced display for featured tracker (North Star design for any Main Focus)
                if tracker == trackerOrder.first {
                    enhancedMainFocusDisplay(for: tracker)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
        .frame(minHeight: tracker == trackerOrder.first ? 200 : 80)
        .background(trackerBackground)
    }

    // MARK: - Enhanced Main Focus Display (North Star Design for Any Tracker)
    @ViewBuilder
    private func enhancedMainFocusDisplay(for tracker: TrackerType) -> some View {
        switch tracker {
        case .fasting:
            enhancedFastingDisplay
        case .weight:
            enhancedWeightDisplay
        case .hydration:
            enhancedHydrationDisplay
        case .sleep:
            enhancedSleepDisplay
        case .mood:
            enhancedMoodDisplay
        }
    }

    @ViewBuilder
    private var enhancedFastingDisplay: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Three-column layout with interactive elements
            HStack(alignment: .center, spacing: 16) {
                // Left: 7-day average
                VStack(alignment: .leading, spacing: 4) {
                    Text("7-Day Avg")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))
                    Text(averageFastingTime)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Center: Progress ring (using exact same component as main tracker)
                VStack(spacing: 8) {
                    FastingProgressRing(
                        progress: fastingManager.progress,
                        isActive: fastingManager.isActive,
                        fastingGoalHours: fastingManager.fastingGoalHours,
                        size: 80
                    )
                }

                // Right: Goal end time (interactive)
                goalEndNavigation
            }

            // Meta row (interactive)
            metaRow
        }
    }

    // Enhanced Weight Display (North Star Design)
    @ViewBuilder
    private var enhancedWeightDisplay: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Three-column layout following Fasting pattern
            HStack(alignment: .center, spacing: 16) {
                // Left: Weight trend
                VStack(alignment: .leading, spacing: 4) {
                    Text("7-Day Avg")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                    Text("--.-")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Center: Weight progress visualization
                VStack(spacing: 8) {
                    Image(systemName: "scalemass")
                        .font(.system(size: 40))
                        .foregroundColor(Color(hex: "#1ABC9C"))

                    Text("Goal Progress")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }

                // Right: Current weight (interactive)
                VStack(alignment: .trailing, spacing: 4) {
                    if let latestWeight = weightManager.latestWeight {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Current Weight")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Color(hex: "#D4AF37").opacity(0.9))
                            Text("\(latestWeight.weight, specifier: "%.1f") lbs")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(Color(hex: "#D4AF37"))
                        }
                    } else {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Add Weight")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Color(hex: "#D4AF37").opacity(0.9))
                            Text("-- lbs")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(Color(hex: "#D4AF37"))
                        }
                    }
                }
            }
        }
    }

    // Enhanced Hydration Display (North Star Design)
    @ViewBuilder
    private var enhancedHydrationDisplay: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Three-column layout following Fasting pattern
            HStack(alignment: .center, spacing: 16) {
                // Left: Daily average
                VStack(alignment: .leading, spacing: 4) {
                    Text("7-Day Avg")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                    Text("--.-")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Center: Hydration progress ring
                VStack(spacing: 8) {
                    Image(systemName: "drop.fill")
                        .font(.system(size: 40))
                        .foregroundColor(Color(hex: "#1ABC9C"))

                    let dailyIntake = hydrationManager.todaysTotalInPreferredUnitComputed
                    Text("\(Int((dailyIntake / 64.0) * 100))%")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }

                // Right: Today's intake (interactive)
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Today's Intake")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(hex: "#D4AF37").opacity(0.9))
                    let dailyIntake = hydrationManager.todaysTotalInPreferredUnitComputed
                    let unit = hydrationManager.currentUnitAbbreviationComputed
                    Text(String(format: "%.1f %@", dailyIntake, unit))
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(Color(hex: "#D4AF37"))
                }
            }
        }
    }

    // Enhanced Sleep Display (North Star Design)
    @ViewBuilder
    private var enhancedSleepDisplay: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Three-column layout following Fasting pattern
            HStack(alignment: .center, spacing: 16) {
                // Left: Sleep average
                VStack(alignment: .leading, spacing: 4) {
                    Text("7-Day Avg")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                    Text("--:--")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Center: Sleep quality indicator
                VStack(spacing: 8) {
                    Image(systemName: "moon.fill")
                        .font(.system(size: 40))
                        .foregroundColor(Color(hex: "#1ABC9C"))

                    Text("Quality")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }

                // Right: Last night sleep (interactive)
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Last Night")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(hex: "#D4AF37").opacity(0.9))
                    if let lastNight = sleepManager.lastNightSleep {
                        Text(lastNight.formattedDuration)
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(Color(hex: "#D4AF37"))
                    } else {
                        Text("-- hrs")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(Color(hex: "#D4AF37"))
                    }
                }
            }
        }
    }

    // Enhanced Mood Display (North Star Design)
    @ViewBuilder
    private var enhancedMoodDisplay: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Three-column layout following Fasting pattern
            HStack(alignment: .center, spacing: 16) {
                // Left: Weekly trend
                VStack(alignment: .leading, spacing: 4) {
                    Text("7-Day Avg")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                    Text("-- m")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Center: Mood indicator
                VStack(spacing: 8) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 40))
                        .foregroundColor(Color(hex: "#1ABC9C"))

                    Text("Balance")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }

                // Right: Today's mood (interactive)
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Today's Mood")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(hex: "#D4AF37").opacity(0.9))
                    if let avgMood = moodManager.todayAverageMood {
                        Text(String(format: "%.1f m", avgMood))
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(Color(hex: "#D4AF37"))
                    } else {
                        Text("-- m")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(Color(hex: "#D4AF37"))
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var trackerBackground: some View {
        // Industry Standard: Featured card with distinctive background for visual hierarchy
        // Reference: Apple Health app featured sections, Fitbit primary stats
        RoundedRectangle(cornerRadius: 16)
            .fill(.ultraThinMaterial)
            .overlay(
                // Hero card treatment with distinctive teal background
                RoundedRectangle(cornerRadius: 16)
                    .fill(tracker == trackerOrder.first ?
                          Color(hex: "#1ABC9C").opacity(0.25) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        LinearGradient(
                            colors: tracker == trackerOrder.first ? [
                                // Enhanced border for featured tracker
                                Color(hex: "#1ABC9C").opacity(0.6),
                                Color(hex: "#D4AF37").opacity(0.4)
                            ] : [
                                // Subtle border for regular trackers
                                Color(hex: "#1ABC9C").opacity(0.4),
                                Color(hex: "#D4AF37").opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: tracker == trackerOrder.first ? 2.0 : 1.5
                    )
            )
            .shadow(color: Color.black.opacity(0.12), radius: 8, x: 0, y: 4)  // Elevation from spec
    }

    @ViewBuilder
    private var fastingTimeNavigation: some View {
        NavigationLink(destination: EditFastTimesView()) {
            VStack(alignment: .trailing, spacing: 2) {
                Text(fastingManager.isActive ? "Fasting Time" : "Time Since Last Fast")
                    .font(.caption2)
                    .foregroundColor(Color(hex: "#D4AF37").opacity(0.8))
                Text(fastingDisplayValue)
                    .font(.system(.title3, design: .rounded, weight: .semibold))
                    .foregroundColor(Color(hex: "#D4AF37"))
            }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var goalEndNavigation: some View {
        NavigationLink(destination: GoalSettingsView()) {
            VStack(alignment: .trailing, spacing: 4) {
                Text(fastingManager.isActive ? "End Goal" : "Last Fast")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(hex: "#D4AF37").opacity(0.9))
                Text(goalEndTime)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: "#D4AF37"))
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, alignment: .trailing)
    }

    // MARK: - Meta Row (Following Luxury Spec Layout)
    /// Meta row with start time • target • % complete (equal spacing, center aligned)
    @ViewBuilder
    private var metaRow: some View {
        if tracker == .fasting && tracker == trackerOrder.first {
            HStack {
                // Start time - Interactive
                if fastingManager.isActive, let startTime = fastingManager.currentSession?.startTime {
                    NavigationLink(destination: EditStartTimeView()) {
                        VStack(spacing: 2) {
                            Text("Start")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(Color(hex: "#D0D4DA"))
                            Text(formatTime(startTime))
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                        }
                    }
                    .buttonStyle(.plain)
                }

                Spacer()

                // Target time - Interactive (connects to goal setting)
                if fastingManager.isActive {
                    NavigationLink(destination: GoalSettingsView()) {
                        VStack(spacing: 2) {
                            Text("Target")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(Color(hex: "#D0D4DA"))
                            Text("\(Int(fastingManager.fastingGoalHours))h")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                        }
                    }
                    .buttonStyle(.plain)
                }

                Spacer()

                // Progress percentage
                VStack(spacing: 2) {
                    Text("Progress")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(Color(hex: "#D4AF37").opacity(0.9))
                    Text("\(Int(fastingManager.progress * 100))%")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(Color(hex: "#D4AF37"))
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.black.opacity(0.2))
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
        }
    }

    // MARK: - Enhanced Tracker Views (Following Luxury Spec)
    @ViewBuilder
    private func enhancedTrackerView(for tracker: TrackerType) -> some View {
        switch tracker {
        case .weight:
            VStack(alignment: .leading, spacing: 8) {
                // Status chip for weight tracking
                if tracker == trackerOrder.first {
                    statusChip(isActive: !weightManager.weightEntries.isEmpty)
                }

                // Weight display with units - connected to real data
                HStack(alignment: .center) {
                    Text("Current Weight")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)

                    Spacer()

                    if let latestWeight = weightManager.latestWeight {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("\(latestWeight.weight, specifier: "%.1f") lbs")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(Color(hex: "#1ABC9C"))
                            Text(dateFormatter.string(from: latestWeight.date))
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                                            } else {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("-- lbs")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(Color(hex: "#1ABC9C"))
                            Text("No data yet")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                                            }
                }
            }

        case .sleep:
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .center) {
                    Text("Last Night")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("-- hrs")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(Color(hex: "#1ABC9C"))
                        Text("No data yet")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                                    }
            }

        case .hydration:
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .center) {
                    Text("Daily Goal")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("0%")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(Color(hex: "#1ABC9C"))
                        Text("0 / 64 oz")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                                    }
            }

        case .mood:
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .center) {
                    Text("Today's Mood")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)

                    Spacer()

                    if let avgMood = moodManager.todayAverageMood,
                       let avgEnergy = moodManager.todayAverageEnergy {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("\(String(format: "%.1f", avgMood)) m")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(Color(hex: "#1ABC9C"))
                            Text("\(String(format: "%.1f", avgEnergy)) e")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(Color(hex: "#1ABC9C"))
                        }
                                            } else {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("-- m")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(Color(hex: "#1ABC9C"))
                            Text("-- e")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(Color(hex: "#1ABC9C"))
                        }
                                            }
                }
            }

        case .fasting:
            // This case is handled separately above
            EmptyView()
        }
    }

    // MARK: - Time Formatting Helper
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    // MARK: - Status Chip (Following Luxury Spec Design)
    /// Creates a status chip with 12pt radius following spec requirements
    @ViewBuilder
    private func statusChip(isActive: Bool) -> some View {
        Text(isActive ? "Active" : "Paused")
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(isActive ? .white : Color(hex: "#D0D4DA"))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(isActive ? Color(hex: "#1ABC9C") : Color.gray.opacity(0.3))
                    .shadow(color: isActive ? Color(hex: "#1ABC9C").opacity(0.3) : Color.clear, radius: 2, x: 0, y: 1)
            )
    }

// MARK: - Simple Display Value for Non-Featured Trackers
    private func simpleDisplayValue(for tracker: TrackerType) -> String {
        switch tracker {
        case .fasting:
            return fastingDisplayValue

        case .weight:
            if let latestWeight = weightManager.latestWeight {
                return String(format: "%.1f lbs", latestWeight.weight)
            }
            return "— lbs"

        case .hydration:
            // Following Weight pattern: Use computed properties for automatic SwiftUI updates
            let dailyIntake = hydrationManager.todaysTotalInPreferredUnitComputed
            let unit = hydrationManager.currentUnitAbbreviationComputed
            return String(format: "%.1f %@", dailyIntake, unit)

        case .sleep:
            if let lastNight = sleepManager.lastNightSleep {
                return lastNight.formattedDuration
            }
            return "— hrs"

        case .mood:
            if let avgMood = moodManager.todayAverageMood,
               let avgEnergy = moodManager.todayAverageEnergy {
                return String(format: "%.1f m %.1f e", avgMood, avgEnergy)
            }

            // Fallback to individual values if only one is available
            if let avgMood = moodManager.todayAverageMood {
                return String(format: "%.1f m", avgMood)
            }

            if let avgEnergy = moodManager.todayAverageEnergy {
                return String(format: "%.1f e", avgEnergy)
            }

            return "No data"
        }
    }
}


// MARK: - FastingProgressRing (Extracted from ContentView for consistency)
struct FastingProgressRing: View {
    let progress: Double
    let isActive: Bool
    let fastingGoalHours: Double
    let size: CGFloat

    // Gradient colors for progress ring - transitions through stages (matching ContentView)
    private var progressGradientColors: [Color] {
        [
            Color(red: 0.2, green: 0.6, blue: 0.9),   // 0%: Blue (start)
            Color(red: 0.2, green: 0.7, blue: 0.8),   // 25%: Teal
            Color(red: 0.2, green: 0.8, blue: 0.7),   // 50%: Cyan
            Color(red: 0.3, green: 0.8, blue: 0.5),   // 75%: Green-teal
            Color(red: 0.4, green: 0.9, blue: 0.4),   // 90%: Vibrant green
            Color(red: 0.3, green: 0.85, blue: 0.3)   // 100%: Celebration green
        ]
    }

    var body: some View {
        ZStack {
            // Educational stage icons positioned around the circle (matching ContentView)
            ForEach(FastingStage.relevantStages(for: fastingGoalHours)) { stage in
                let midpointHour = Double(stage.startHour + stage.endHour) / 2.0
                let angle = (midpointHour / 24.0) * 360.0 - 90.0 // -90 to start at top
                let radius: CGFloat = size * 0.8 // Scale radius to component size
                let x = radius * cos(angle * .pi / 180)
                let y = radius * sin(angle * .pi / 180)

                Text(stage.icon)
                    .font(.system(size: size * 0.2)) // Scale icon size
                    .background(
                        Circle()
                            .fill(Color.white)
                            .frame(width: size * 0.25, height: size * 0.25)
                            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                    )
                    .offset(x: x, y: y)
            }

            // Timer Circle (exact same as ContentView, scaled)
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: size * 0.08) // Scale line width
                    .frame(width: size, height: size)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        isActive ?
                        AngularGradient(
                            gradient: Gradient(colors: progressGradientColors),
                            center: .center,
                            startAngle: .degrees(0),
                            endAngle: .degrees(360)
                        ) : AngularGradient(
                            gradient: Gradient(colors: [Color.gray, Color.gray]),
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: size * 0.08, lineCap: .round)
                    )
                    .frame(width: size, height: size)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: progress)

                // Progress Percentage (centered)
                Text("\(Int(progress * 100))%")
                    .font(.system(size: size * 0.15, weight: .semibold))
                    .foregroundColor(.white.opacity(0.9))
            }
        }
    }
}

// MARK: - Color Extension for Hex Values (Following Luxury Spec)

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    HubView(shouldPopToRoot: .constant(false))
        .environmentObject(FastingManager())
        .environmentObject(HydrationManager())
}