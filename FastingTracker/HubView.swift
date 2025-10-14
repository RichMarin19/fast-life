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
        NavigationView {
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
        NavigationLink(destination: destinationView) {
            HStack(spacing: 16) {
                // Luxury SF Symbol icon with emerald accent (following spec)
                Image(systemName: tracker.icon)
                    .font(.system(size: tracker == trackerOrder.first ? 32 : 24, weight: .medium))
                    .foregroundColor(tracker == trackerOrder.first ? Color(hex: "#1ABC9C") : .white)
                    .shadow(color: tracker == trackerOrder.first ? Color(hex: "#1ABC9C").opacity(0.3) : Color.clear, radius: 4, x: 0, y: 0)

                // Tracker info section
                VStack(alignment: .leading, spacing: 6) {
                    // Tracker name with dynamic sizing based on position
                    HStack(spacing: 12) {
                        Text(tracker.displayName)
                            .font(.system(tracker == trackerOrder.first ? .title3 : .title2, design: .rounded, weight: .semibold))
                            .foregroundColor(.white)

                        // Status chip for featured tracker
                        if tracker == trackerOrder.first && tracker == .fasting {
                            statusChip(isActive: fastingManager.isActive)
                        }

                        // For non-featured trackers, add the value on the right side
                        if tracker != trackerOrder.first {
                            Spacer()

                            if tracker == .fasting {
                                // Fasting with context label above value
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text(fastingManager.isActive ? "Time Since Fast Started" : "Time Since Last Fast")
                                        .font(.caption2)
                                        .foregroundColor(.white.opacity(0.7))

                                    Text(simpleDisplayValue(for: tracker))
                                        .font(.system(.title3, design: .rounded, weight: .semibold))
                                        .foregroundColor(Color("FLWarning"))
                                }
                            } else {
                                Text(simpleDisplayValue(for: tracker))
                                    .font(.system(.title3, design: .rounded, weight: .semibold))
                                    .foregroundColor(Color("FLWarning"))
                                    .multilineTextAlignment(.center)
                            }
                        } else {
                            Spacer()
                        }
                    }

                    // Dynamic enhanced display for featured tracker (first in order)
                    if tracker == trackerOrder.first {
                        // Enhanced display for featured tracker (4pt grid alignment system)
                        VStack(alignment: .leading, spacing: 12) {
                            // Enhanced display for fasting tracker
                            if tracker == .fasting {
                                // Enhanced time label with better visibility
                                Text(fastingManager.isActive ? "Fasting Time" : "Time Since Last Fast")
                                    .font(.caption2)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(
                                        Capsule()
                                            .fill(Color.black.opacity(0.3))
                                            .background(
                                                Capsule()
                                                    .fill(.ultraThinMaterial)
                                            )
                                    )

                                // Restructured layout with progress ring and percentage
                                HStack(alignment: .top, spacing: 20) {
                                    // Left side - Time display
                                    Text(fastingDisplayValue)
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                        .foregroundColor(fastingManager.isActive ? .white : Color("FLWarning"))

                                    Spacer()

                                    // Right side - Progress ring with percentage underneath
                                    VStack(spacing: 6) {
                                        MiniProgressRing(
                                            progress: fastingManager.progress,
                                            isActive: fastingManager.isActive,
                                            size: 44
                                        )

                                        // Progress percentage underneath ring
                                        if fastingManager.isActive {
                                            Text("\(Int(fastingManager.progress * 100))%")
                                                .font(.caption)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.white.opacity(0.9))
                                        }
                                    }
                                }

                                // Meta row with start time • target • % (luxury spec requirement)
                                metaRow

                                // Streak display (bottom row)
                                if fastingManager.currentStreak > 0 {
                                    HStack {
                                        HStack(spacing: 4) {
                                            Image(systemName: "flame.fill")
                                                .font(.caption2)
                                                .foregroundColor(.orange)
                                            Text("\(fastingManager.currentStreak) day\(fastingManager.currentStreak == 1 ? "" : "s") streak")
                                                .font(.caption2)
                                                .foregroundColor(.orange.opacity(0.9))
                                        }

                                        Spacer()
                                    }
                                }
                            } else {
                                // Enhanced display for other featured trackers
                                enhancedTrackerView(for: tracker)
                            }
                        }
                    }
                }

                Spacer()

                // Navigation chevron
                Image(systemName: "chevron.right.circle.fill")
                    .font(.title2)
                    .foregroundColor(Color("FLSecondary"))
                    .opacity(0.8)
            }
            .padding(20)
            .frame(maxWidth: .infinity)
            .frame(minHeight: tracker == trackerOrder.first ? 200 : 80)
            .background(
                // Luxury glass-morphism cards (following spec)
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        Color(hex: "#1ABC9C").opacity(0.4),    // accent.primary
                                        Color(hex: "#D4AF37").opacity(0.2)     // accent.gold
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
                    .shadow(color: Color.black.opacity(0.12), radius: 8, x: 0, y: 4)  // Elevation from spec
            )
        }
    }

    // MARK: - Meta Row (Following Luxury Spec Layout)
    /// Meta row with start time • target • % complete (equal spacing, center aligned)
    @ViewBuilder
    private var metaRow: some View {
        if tracker == .fasting && tracker == trackerOrder.first {
            HStack {
                // Start time
                if fastingManager.isActive, let startTime = fastingManager.currentSession?.startTime {
                    VStack(spacing: 2) {
                        Text("Start")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(Color(hex: "#D0D4DA"))
                        Text(formatTime(startTime))
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                    }
                }

                Spacer()

                // Target time
                if fastingManager.isActive {
                    VStack(spacing: 2) {
                        Text("Target")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(Color(hex: "#D0D4DA"))
                        Text("\(Int(fastingManager.fastingGoalHours))h")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                    }
                }

                Spacer()

                // Progress percentage
                VStack(spacing: 2) {
                    Text("Progress")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(Color(hex: "#D0D4DA"))
                    Text("\(Int(fastingManager.progress * 100))%")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(Color(hex: "#1ABC9C"))
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

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("--/10")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(Color(hex: "#1ABC9C"))
                        Text("Not rated")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
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
                return String(format: "%.1f mood %.1f energy", avgMood, avgEnergy)
            }

            // Fallback to individual values if only one is available
            if let avgMood = moodManager.todayAverageMood {
                return String(format: "%.1f mood", avgMood)
            }

            if let avgEnergy = moodManager.todayAverageEnergy {
                return String(format: "%.1f energy", avgEnergy)
            }

            return "No data"
        }
    }
}

// MARK: - MiniProgressRing (Reusable component for Hub cards)
struct MiniProgressRing: View {
    let progress: Double
    let isActive: Bool
    let size: CGFloat

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
            // Luxury background with enhanced depth
            Circle()
                .fill(Color.white)
                .frame(width: size + 8, height: size + 8)
                .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)

            // Refined background ring with premium styling
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.5)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 3
                )
                .frame(width: size, height: size)

            // Enhanced progress ring with luxury gradient and glow
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
                        gradient: Gradient(colors: [Color.gray.opacity(0.6), Color.gray.opacity(0.8)]),
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 5, lineCap: .round)
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
                .shadow(color: isActive ? Color.blue.opacity(0.3) : Color.clear, radius: 2, x: 0, y: 0)
                .animation(.linear(duration: 1), value: progress)
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
    HubView()
        .environmentObject(FastingManager())
}