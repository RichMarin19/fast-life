import SwiftUI

/// HubView - Central dashboard displaying all tracker summaries
/// Following Apple SwiftUI MVVM patterns and HIG guidelines for tab-based navigation
/// Reference: https://developer.apple.com/design/human-interface-guidelines/tab-bars
struct HubView: View {
    // MARK: - Environment Objects (Following HANDOFF.md state management patterns)
    @EnvironmentObject var fastingManager: FastingManager
    @StateObject private var weightManager = WeightManager()
    @StateObject private var hydrationManager = HydrationManager()
    @StateObject private var sleepManager = SleepManager()
    @StateObject private var moodManager = MoodManager()
    // Note: Mood tracker handles both mood and energy data

    // MARK: - State Management (Apple SwiftUI Guidelines)
    @AppStorage("hubTrackerOrder") private var trackerOrderData: Data = Data()
    @State private var trackerOrder: [TrackerType] = [.fasting, .weight, .sleep, .hydration, .mood]
    @State private var draggedTracker: TrackerType?

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // MARK: - Tracker List (5 trackers in full-width layout)
                    LazyVStack(spacing: 12) {
                        ForEach(trackerOrder, id: \.self) { tracker in
                            TrackerSummaryCard(tracker: tracker, trackerOrder: trackerOrder)
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
                    .padding()

                    Spacer()
                        .frame(height: 20)
                }
            }
            .background(
                // Navy background with gradient using Asset Catalog colors
                LinearGradient(
                    colors: [
                        Color("FLPrimary"),        // Navy blue
                        Color("FLSecondary")       // Secondary accent
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
            .navigationTitle("Hub")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear {
            loadTrackerOrder()
        }
        .onChange(of: trackerOrder) { _, newOrder in
            saveTrackerOrder(newOrder)
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
                // Show time since last fast
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
                // Icon with accent color (larger for full-width)
                Text(tracker.icon)
                    .font(.system(size: 50))

                // Tracker info section
                VStack(alignment: .leading, spacing: 6) {
                    // Tracker name
                    Text(tracker.displayName)
                        .font(.system(.title3, design: .rounded, weight: .semibold))
                        .foregroundColor(.white)

                    // Dynamic enhanced display for featured tracker (first in order)
                    if tracker == trackerOrder.first {
                        // Enhanced display for featured tracker (larger size with more info)
                        VStack(alignment: .leading, spacing: 8) {
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
                                // Enhanced display for other featured trackers (placeholder for future implementation)
                                Text(tracker.displayName)
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)

                                Text("Enhanced view - more details")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                    } else {
                        // Standard display for non-featured trackers
                        if tracker == .fasting {
                            // Simple fasting display
                            VStack(alignment: .leading, spacing: 4) {
                                Text(fastingManager.isActive ? "Fasting Time" : "Time Since Last Fast")
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.7))

                                Text(fastingDisplayValue)
                                    .font(.subheadline)
                                    .foregroundColor(fastingManager.isActive ? .white : Color("FLWarning"))
                                    .opacity(0.9)
                            }
                        } else {
                            // Other trackers - simple display
                            Text(fastingDisplayValue)
                                .font(.subheadline)
                                .foregroundColor(Color("FLWarning"))
                                .opacity(0.9)
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
                // Glass-morphism effect on navy background
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        Color("FLSecondary").opacity(0.6),
                                        Color("FLWarning").opacity(0.3)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
            )
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

#Preview {
    HubView()
        .environmentObject(FastingManager())
}