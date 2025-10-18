import SwiftUI

// MARK: - Weight Components
// Additional weight tracker components extracted for better modularity

/*
 ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 📝 OPT-OUT FEATURE TEMPLATE (Standardized Pattern)
 ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

 WHEN TO USE:
 Add this pattern to ANY content view that shows:
   • Educational tips
   • Behavioral nudges
   • Motivational messages
   • Progress summaries
   • Insights or smart coaching

 INDUSTRY STANDARD:
 Follows Spotify, Instagram, Netflix, Apple Health pattern:
   • Granular opt-out (per item, not per category)
   • Centralized hub to restore content (Manage My Experience)
   • User control = trust + engagement

 HOW TO IMPLEMENT:

 1️⃣ IMPORT MANAGER (at top of your view):
    @ObservedObject private var optOutManager = ContentOptOutManager.shared

 2️⃣ UNIQUE CONTENT ID (constant in your view):
    private let contentID = "unique_content_id_v1"
    // Example IDs:
    //   - "progress_story_trends_v1"
    //   - "tip_water_intake_v1"
    //   - "nudge_log_weight_streak_v1"
    //   - "motivation_milestone_5lb_v1"

 3️⃣ CHECK OPT-OUT STATUS (before showing content):
    if !optOutManager.isContentOptedOut(id: contentID) {
        // Show your content here
    }

 4️⃣ ADD OPT-OUT BUTTON (in toolbar or inline):
    .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
            Button {
                optOutManager.optOutContent(
                    id: contentID,
                    category: .progressSummaries,  // Choose: .educationalInsights, .behavioralNudges, .motivationalMessages, .progressSummaries
                    text: "Your Progress Story"   // Display name shown in Manage My Experience
                )
                dismiss()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "eye.slash")
                        .font(.system(size: 14))
                    Text("Don't show again")
                        .font(.system(size: 14))
                }
                .foregroundColor(.secondary)
            }
        }
    }

 RESULT:
   ✅ User opts out → Content no longer appears
   ✅ Item shows up in "Manage My Experience" card
   ✅ User can restore individual items or all at once
   ✅ Auto-syncs via @AppStorage (iCloud compatible)

 REFERENCE IMPLEMENTATION:
   See WeightTrendsView struct below (lines 349-460)

 ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 */

struct WeightStatsView: View {
    @ObservedObject var weightManager: WeightManager

    var body: some View {
        VStack(spacing: 12) {
            Text("Statistics")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                WeightChangeStatCard(
                    title: "7-Day Change",
                    weightChange: weightManager.weightChange(since: Calendar.current.date(byAdding: .day, value: -7, to: Date())!)
                )

                WeightChangeStatCard(
                    title: "30-Day Change",
                    weightChange: weightManager.weightChange(since: Calendar.current.date(byAdding: .day, value: -30, to: Date())!)
                )

                StatCard(
                    title: "Average Weight",
                    value: weightManager.averageWeight
                        .map { String(format: "%.1f \("lbs")", ($0)) } ?? "N/A",
                    icon: "chart.bar",
                    color: .orange
                )

                StatCard(
                    title: "Total Entries",
                    value: "\(weightManager.weightEntries.count)",
                    icon: "number",
                    color: .green
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Supporting Components

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text(value)
                .font(.title3)
                .fontWeight(.bold)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(8)
    }
}

struct WeightChangeStatCard: View {
    let title: String
    let weightChange: Double?

    var body: some View {
        VStack(spacing: 8) {
            if let change = weightChange {
                // Arrow icon based on gain/loss
                Image(systemName: change >= 0 ? "arrow.up.right" : "arrow.down.right")
                    .font(.title2)
                    .foregroundColor(change >= 0 ? .red : .green)

                // Weight change value with arrow
                HStack(spacing: 4) {
                    Text(String(format: "%.1f \("lbs")", (abs(change))))
                        .font(.title3)
                        .fontWeight(.bold)
                    Image(systemName: change >= 0 ? "arrow.up" : "arrow.down")
                        .font(.title3)
                        .fontWeight(.bold)
                }
                .foregroundColor(change >= 0 ? .red : .green)
            } else {
                Image(systemName: "calendar")
                    .font(.title2)
                    .foregroundColor(.gray)

                Text("N/A")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.gray)
            }

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(8)
    }
}

struct WeightHistoryListView: View {
    @ObservedObject var weightManager: WeightManager

    var body: some View {
        VStack(spacing: 12) {
            Text("Weight History")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            ForEach(Array(weightManager.weightEntries.prefix(10))) { entry in
                WeightHistoryRow(entry: entry, weightManager: weightManager)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            weightManager.deleteWeightEntry(entry)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                Divider()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

struct WeightHistoryRow: View {
    let entry: WeightEntry
    let weightManager: WeightManager
    @State private var showingDeleteAlert = false

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text(entry.date, style: .date)
                        .font(.headline)
                    Text("•")
                        .foregroundColor(.secondary)
                    Text(entry.date, style: .time)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                HStack(spacing: 8) {
                    Text(entry.source.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if let bmi = entry.bmi {
                        Text("BMI: \(bmi, specifier: "%.1f")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if let bodyFat = entry.bodyFat {
                        Text("BF: \(bodyFat, specifier: "%.1f")%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            Text("\(weightManager.displayWeight(for: entry), specifier: "%.1f") \("lbs")")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(Color("FLPrimary"))
        }
        .contentShape(Rectangle())
        .contextMenu {
            Button(role: .destructive, action: { showingDeleteAlert = true }) {
                Label("Delete", systemImage: "trash")
            }
        }
        .alert("Delete Weight Entry", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                weightManager.deleteWeightEntry(entry)
            }
        } message: {
            Text("Are you sure you want to delete this weight entry?")
        }
    }
}

struct FirstTimeWeightSetupView: View {
    @ObservedObject var weightManager: WeightManager
    @Binding var weightGoal: Double
    @Binding var showGoalLine: Bool
    @Environment(\.dismiss) var dismiss

    @State private var currentWeightString: String = ""
    @State private var goalWeightString: String = ""
    @State private var showError: Bool = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "scalemass.fill")
                            .font(.system(size: 60))
                            .foregroundColor(Color("FLPrimary"))

                        Text("Welcome to Weight Tracking")
                            .font(.title2)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)

                        Text("Let's get started by setting up your weight goals")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top, 40)

                    // Current Weight Input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Current Weight")
                            .font(.headline)
                            .foregroundColor(.primary)

                        HStack {
                            TextField("Enter weight", text: $currentWeightString)
                                .keyboardType(.decimalPad)
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .multilineTextAlignment(.center)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)

                            Text("lbs")
                                .font(.title3)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal)

                    // Goal Weight Input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Goal Weight")
                            .font(.headline)
                            .foregroundColor(.primary)

                        HStack {
                            TextField("Enter goal", text: $goalWeightString)
                                .keyboardType(.decimalPad)
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .multilineTextAlignment(.center)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)

                            Text("lbs")
                                .font(.title3)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal)

                    // Error message
                    if showError {
                        Text("Please enter valid weights")
                            .font(.caption)
                            .foregroundColor(.red)
                    }

                    // Get Started Button
                    Button(action: saveAndContinue) {
                        Text("Get Started")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color("FLPrimary"))
                            .cornerRadius(8)
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)

                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .interactiveDismissDisabled() // Prevent dismissal without entering data
        }
    }

    private func saveAndContinue() {
        // Validate inputs
        guard let currentWeight = Double(currentWeightString),
              let goalWeight = Double(goalWeightString),
              currentWeight > 0,
              goalWeight > 0 else {
            showError = true
            return
        }

        // Save current weight entry
        let entry = WeightEntry(
            id: UUID(),
            date: Date(),
            weight: currentWeight,
            bmi: nil,
            bodyFat: nil,
            source: .manual
        )
        weightManager.addWeightEntry(entry)

        // Save goal weight
        weightGoal = goalWeight

        // Enable goal line by default
        showGoalLine = true

        // Dismiss the sheet
        dismiss()
    }
}
struct WeightTrendsView: View {
    @ObservedObject var weightManager: WeightManager
    @Environment(\.dismiss) private var dismiss

    // Unified opt-out system: ContentOptOutManager for all cards + global
    @ObservedObject private var optOutManager = ContentOptOutManager.shared

    // Content IDs for opt-out tracking
    private let contentID_ProgressStory = "progress_story_v1"        // Global (toolbar button)
    private let contentID_7Day = "progress_story_7day_v1"            // 7-day card
    private let contentID_30Day = "progress_story_30day_v1"          // 30-day card
    private let contentID_Banner = "progress_story_banner_v1"        // Motivational banner
    private let contentID_Recap = "progress_story_recap_v1"          // Recap row
    private let contentID_Tip = "progress_story_tip_v1"              // Did You Know

    // MARK: - Trend State Logic (Layer 1)

    /// Trend state classification per Stacked_v1.1 spec
    enum TrendState {
        case improving  // Δ < -0.2 (loss)
        case regressing // Δ > +0.2 (gain)
        case flat       // |Δ| ≤ 0.2
    }

    /// Calculate signed delta for a period
    /// Returns signed value (negative = loss, positive = gain)
    private func calculateDelta(days: Int) -> Double? {
        guard weightManager.weightEntries.count >= 2 else { return nil }

        let sortedEntries = weightManager.weightEntries.sorted { $0.date < $1.date }
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let recentEntries = sortedEntries.filter { $0.date >= cutoffDate }

        guard recentEntries.count >= 2,
              let firstWeight = recentEntries.first?.weight,
              let lastWeight = recentEntries.last?.weight else {
            return nil
        }

        // Positive = gain, Negative = loss
        return lastWeight - firstWeight
    }

    /// Determine trend state from delta
    private func trendState(for delta: Double) -> TrendState {
        if delta < -0.2 { return .improving }
        if delta > 0.2 { return .regressing }
        return .flat
    }

    /// Calculate net delta across 30 days for recap row
    private var netDelta30d: Double {
        return calculateDelta(days: 30) ?? 0
    }

    /// Calculate best streak (placeholder - TODO)
    private var bestStreak: Int {
        return weightManager.weightEntries.count // Placeholder logic
    }

    /// Total entries count
    private var totalEntries: Int {
        return weightManager.weightEntries.count
    }

    /// Banner text based on 7-day trend state
    /// Per Stacked_v1.1 spec: Dynamic behavioral copy
    private func banner7Text(for state: TrendState) -> String {
        switch state {
        case .improving:
            return "Small wins compound. Keep stacking the days."
        case .regressing:
            return "Course‑correct today. One choice changes the trend."
        case .flat:
            return "Consistency is power. Nudge your routine by 1%."
        }
    }

    /// Banner accent color based on trend state
    private func bannerAccentColor(for state: TrendState) -> Color {
        switch state {
        case .improving:
            return Theme.ColorToken.stateSuccess
        case .regressing:
            return Theme.ColorToken.stateError
        case .flat:
            return Theme.ColorToken.accentInfo
        }
    }

    /// Random "Did You Know" tip for educational banner
    /// Per Stacked_v1.1 spec: Max ~80 chars, no medical claims
    /// FASTING-FRIENDLY: Avoids time-specific meal names (breakfast/lunch/dinner)
    /// Fast LIFe users have flexible eating windows, so use universal language
    private func randomDidYouKnowTip() -> String {
        let tips = [
            "Drinking water before meals can reduce calorie intake.",
            "Sleep loss increases hunger hormones; protect your 7–8 hours.",
            "Protein at your first meal improves satiety for the day.",  // Fasting-friendly!
            "Consistent weigh-ins help track trends, not daily fluctuations.",
            "Strength training preserves muscle during weight loss."
        ]
        return tips.randomElement() ?? tips[0]
    }

    /// Calculate weight change over a specific number of days
    /// Returns (amount: Double, isLoss: Bool) or nil if insufficient data
    private func calculateTrend(days: Int?) -> (amount: Double, isLoss: Bool)? {
        guard weightManager.weightEntries.count >= 2 else { return nil }

        let sortedEntries = weightManager.weightEntries.sorted { $0.date < $1.date }

        if let days = days {
            // Calculate trend for specific period
            let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
            let recentEntries = sortedEntries.filter { $0.date >= cutoffDate }

            guard recentEntries.count >= 2,
                  let firstWeight = recentEntries.first?.weight,
                  let lastWeight = recentEntries.last?.weight else {
                return nil
            }

            let change = firstWeight - lastWeight
            return (amount: abs(change), isLoss: change > 0)
        } else {
            // All-time trend (first to latest)
            guard let firstWeight = sortedEntries.first?.weight,
                  let lastWeight = sortedEntries.last?.weight else {
                return nil
            }

            let change = firstWeight - lastWeight
            return (amount: abs(change), isLoss: change > 0)
        }
    }

    @State private var isAnimating = false  // Animation state for staggered fade-in

    var body: some View {
        NavigationView {
            // Luxury gradient background - Color Refresh v1
            // Per FastLIFe_ProgressStory_ColorRefresh_v1.md: 3-stop breathing gradient
            ZStack {
                // Deep 3-stop navy gradient (Stacked v1.2)
                LinearGradient(
                    colors: [
                        Theme.ColorToken.bgDeepStart,  // Top: #0C1A2B (calm base)
                        Theme.ColorToken.bgDeepMid,    // Mid: #0F2438 (breathing effect)
                        Theme.ColorToken.bgDeepEnd     // Bot: #123449 (depth)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        // TITLE: Your Progress Story (luxury cyan-blue gradient)
                        // Per user requirement: All titles use cyan→blue gradient (Control Center pattern)
                        // Color Refresh v1: SF Pro Rounded for luxury feel
                        Text("Your Progress Story")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
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
                            .frame(maxWidth: .infinity, alignment: .center)  // Centered horizontally
                            .padding(.top, 8)
                            .padding(.bottom, 8)

                        // STACKED LAYOUT v1.1: Narrative flow top-to-bottom

                        // 1. 7-DAY CARD (full-width)
                        if !optOutManager.isContentOptedOut(id: contentID_7Day) {
                            TrendCardFull(
                                periodLabel: "7 DAYS",
                                delta: calculateDelta(days: 7),
                                surface: Theme.ColorToken.surfaceIce,
                                onHide: {
                                    withAnimation(.easeInOut(duration: 0.25)) {
                                        optOutManager.optOutContent(
                                            id: contentID_7Day,
                                            category: .progressSummaries,
                                            text: "7-day trend"
                                        )
                                    }
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                }
                            )
                            .opacity(isAnimating ? 1 : 0)
                            .offset(y: isAnimating ? 0 : 20)
                            .animation(.easeInOut(duration: 0.4).delay(0.1), value: isAnimating)
                        }

                        // 2. MOTIVATIONAL BANNER (based on 7d trend)
                        let delta7d = calculateDelta(days: 7) ?? 0
                        let state7d = trendState(for: delta7d)
                        let bannerText = banner7Text(for: state7d)
                        let bannerAccent = bannerAccentColor(for: state7d)

                        // 2. MOTIVATIONAL BANNER
                        if !optOutManager.isContentOptedOut(id: contentID_Banner) {
                            ProgressBanner(text: bannerText, accent: bannerAccent, onHide: {
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    optOutManager.optOutContent(
                                        id: contentID_Banner,
                                        category: .behavioralNudges,
                                        text: "Progress banner"
                                    )
                                }
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            })
                            .opacity(isAnimating ? 1 : 0)
                            .offset(y: isAnimating ? 0 : 20)
                            .animation(.easeInOut(duration: 0.4).delay(0.2), value: isAnimating)
                        }

                        // 3. 30-DAY CARD (full-width)
                        if !optOutManager.isContentOptedOut(id: contentID_30Day) {
                            TrendCardFull(
                                periodLabel: "30 DAYS",
                                delta: calculateDelta(days: 30),
                                surface: Theme.ColorToken.surfaceIvory,
                                onHide: {
                                    withAnimation(.easeInOut(duration: 0.25)) {
                                        optOutManager.optOutContent(
                                            id: contentID_30Day,
                                            category: .progressSummaries,
                                            text: "30-day trend"
                                        )
                                    }
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                }
                            )
                            .opacity(isAnimating ? 1 : 0)
                            .offset(y: isAnimating ? 0 : 20)
                            .animation(.easeInOut(duration: 0.4).delay(0.3), value: isAnimating)
                        }

                        // 4. RECAP ROW (Net Δ | Streak | Entries)
                        if !optOutManager.isContentOptedOut(id: contentID_Recap) {
                            RecapRow(
                                netDelta: netDelta30d,
                                bestStreak: bestStreak,
                                entries: totalEntries,
                                onHide: {
                                    withAnimation(.easeInOut(duration: 0.25)) {
                                        optOutManager.optOutContent(
                                            id: contentID_Recap,
                                            category: .progressSummaries,
                                            text: "Progress recap"
                                        )
                                    }
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                }
                            )
                            .opacity(isAnimating ? 1 : 0)
                            .offset(y: isAnimating ? 0 : 20)
                            .animation(.easeInOut(duration: 0.4).delay(0.4), value: isAnimating)
                        }

                        // 5. DID YOU KNOW BANNER (optional - show if user has 5+ entries)
                        if totalEntries >= 5 && !optOutManager.isContentOptedOut(id: contentID_Tip) {
                            DidYouKnowBanner(
                                text: randomDidYouKnowTip(),
                                onHide: {
                                    withAnimation(.easeInOut(duration: 0.25)) {
                                        optOutManager.optOutContent(
                                            id: contentID_Tip,
                                            category: .educationalInsights,
                                            text: "Did You Know tip"
                                        )
                                    }
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                }
                            )
                            .opacity(isAnimating ? 1 : 0)
                            .offset(y: isAnimating ? 0 : 20)
                            .animation(.easeInOut(duration: 0.4).delay(0.5), value: isAnimating)
                        }
                    }
                    .padding(.horizontal, 16)  // Consistent 16pt horizontal rhythm
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("Weight Trends")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                // Trigger staggered fade-in animation on view appear
                withAnimation {
                    isAnimating = true
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    // LUXURY OPT-OUT BUTTON (v1.0 - Refined Design)
                    // Per UI/UX Design Note: FastLIFe_UIUX_DontShowAgain_DesignNote.md
                    // Layers: Gradient border + Fade animation + Haptic feedback
                    Button {
                        // Layer 3: Haptic feedback (light tap) = premium responsiveness
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()

                        // Opt out entire Progress Story (global)
                        optOutManager.optOutContent(id: contentID_ProgressStory, category: .progressSummaries, text: "Your Progress Story")

                        // Layer 2: Smooth fade-out animation (0.25s)
                        withAnimation(.easeInOut(duration: 0.25)) {
                            dismiss()
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "eye.slash")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Don't show again")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            // Layer 1: Subtle gradient border (10-15% opacity) = luxury feel
                            Capsule()
                                .fill(Color.white.opacity(0.1))
                                .overlay(
                                    Capsule()
                                        .stroke(
                                            LinearGradient(
                                                colors: [
                                                    Theme.ColorToken.accentPrimary.opacity(0.15),
                                                    Theme.ColorToken.accentPrimary.opacity(0.10)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 1
                                        )
                                )
                                .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 1)
                        )
                    }
                    .buttonStyle(.plain)  // Removes default button press effect
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
// MARK: - Light Card Wrapper (Stacked v1.2)

/// LightCard - Reusable wrapper for light surface cards with opt-out menu
/// Per Stacked v1.2 spec: Light surfaces with ellipsis menu for per-card opt-out
struct LightCard<Content: View>: View {
    let surface: Color
    let content: Content
    let onHide: () -> Void

    init(surface: Color, onHide: @escaping () -> Void, @ViewBuilder content: () -> Content) {
        self.surface = surface
        self.content = content()
        self.onHide = onHide
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Top row: eye.slash icon (top-left) for hiding card
            HStack {
                Button(action: onHide) {
                    Image(systemName: "eye.slash")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Theme.ColorToken.textSecondary)
                        .frame(width: 44, height: 44)  // Apple HIG tap target
                }
                .buttonStyle(.plain)

                Spacer()
            }

            content
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Theme.ColorToken.strokeLight, lineWidth: 1)
                )
                .shadow(color: Theme.ColorToken.shadowCard, radius: 10, x: 0, y: 6)
        )
    }
}

// MARK: - Luxury Progress Story Components (Stacked v1.1)

/*
 ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 📝 PROGRESS STORY PATTERN (Standardized for Reuse)
 ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

 WHEN TO USE:
 Apply this pattern to ANY tracker that needs progress visualization:
   • Hydration Tracker: 7d/30d intake trends
   • Sleep Tracker: 7d/30d sleep quality trends
   • Mood Tracker: 7d/30d stability trends
   • Fasting Tracker: 7d/30d fasting completion trends

 INDUSTRY STANDARD:
 Follows Apple Health, MyFitnessPal, Strava pattern:
   • Stacked narrative (tell a story top-to-bottom)
   • Glass morphism UI (luxury feel on dark gradients)
   • Behavioral copy (adapting to user's trend state)
   • Educational tips (Did You Know banners)

 HOW TO IMPLEMENT:

 1️⃣ TREND CALCULATION (in your view):
    private func calculateDelta(days: Int) -> Double? {
        // Calculate signed delta (negative = improving, positive = regressing)
        // Use your tracker's metric (weight, hours, mood score, etc.)
    }

 2️⃣ TREND STATE LOGIC:
    enum TrendState { case improving, regressing, flat }

    private func trendState(for delta: Double) -> TrendState {
        // Define thresholds for your metric
        if delta < -threshold { return .improving }
        if delta > +threshold { return .regressing }
        return .flat
    }

 3️⃣ USE COMPONENTS:
    TrendCardFull(periodLabel: "7 DAYS", delta: calculateDelta(days: 7))
    ProgressBanner(text: adaptiveMessage, accent: adaptiveColor)
    RecapRow(netDelta: net30d, bestStreak: streak, entries: count)
    DidYouKnowBanner(text: randomTip())

 4️⃣ BACKGROUND:
    ZStack {
        LinearGradient(
            colors: [Theme.ColorToken.bgDeepStart, Theme.ColorToken.bgDeepEnd],
            startPoint: .top, endPoint: .bottom
        ).ignoresSafeArea()

        ScrollView { /* Stacked components with 16pt spacing */ }
    }

 RESULT:
   ✅ Consistent luxury UI across all trackers
   ✅ Reusable components = faster development
   ✅ Industry-standard progress visualization
   ✅ Behavioral psychology = user engagement

 REFERENCE IMPLEMENTATION:
   See WeightTrendsView (lines 420-610) for complete example

 ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 */

/// Progress Banner - Motivational/Action message with accent stripe
/// Per Stacked v1.2 spec: Frosted glass background with opt-out icon
/// ✅ REUSABLE across all trackers - just pass text + accent color
struct ProgressBanner: View {
    let text: String
    let accent: Color
    let onHide: () -> Void  // Hide callback

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Top row: eye.slash icon (top-left)
            HStack {
                Button(action: onHide) {
                    Image(systemName: "eye.slash")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Theme.ColorToken.textSecondary)
                        .frame(width: 44, height: 44)  // Apple HIG tap target
                }
                .buttonStyle(.plain)

                Spacer()
            }

            // Banner content
            HStack(spacing: 12) {
                // Left accent stripe
                Capsule()
                    .fill(accent)
                    .frame(width: 3, height: 28)

                Text(text)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(Theme.ColorToken.textPrimary.opacity(0.9))

                Spacer(minLength: 0)
            }
        }
        .padding(16)
        .background(
            // Stacked v1.2: Frosted glass banner
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Theme.ColorToken.strokeLight, lineWidth: 1)
                )
                .shadow(color: Theme.ColorToken.shadowCard, radius: 8, x: 0, y: 4)
        )
        .accessibilityLabel("Progress tip: \(text)")
    }
}

/// Trend Card Full-Width - Single period display (7D or 30D)
/// Per Stacked v1.2 spec: Light surface card with LightCard wrapper
struct TrendCardFull: View {
    let periodLabel: String  // "7 DAYS" or "30 DAYS"
    let delta: Double?       // Signed value (negative = loss)
    let surface: Color       // surfaceIce or surfaceIvory
    let onHide: () -> Void   // Hide card callback

    private var state: WeightTrendsView.TrendState {
        guard let delta = delta else { return .flat }
        if delta < -0.2 { return .improving }
        if delta > 0.2 { return .regressing }
        return .flat
    }

    private var accent: Color {
        switch state {
        case .improving: return Theme.ColorToken.stateSuccess
        case .regressing: return Theme.ColorToken.stateError
        case .flat: return Theme.ColorToken.textSecondary.opacity(0.8)
        }
    }

    private var tag: String {
        guard let delta = delta else { return "NO DATA" }
        if delta < -0.2 { return "LOST" }
        if delta > 0.2 { return "GAINED" }
        return "FLAT"
    }

    var body: some View {
        LightCard(surface: surface, onHide: onHide) {
            VStack(alignment: .leading, spacing: 12) {
                // Top accent bar (3pt height)
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(accent)
                    .frame(height: 3)
                    .opacity(0.9)

                // Primary number + unit
                HStack(alignment: .lastTextBaseline, spacing: 8) {
                    Text(delta != nil ? String(format: "%.1f", abs(delta!)) : "--")
                        .font(.system(size: 40, weight: .semibold))
                        .foregroundColor(Theme.ColorToken.textPrimary)

                    Text("lbs")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(Theme.ColorToken.textSecondary)

                    Spacer()
                }

                // Tag + Period label
                HStack(spacing: 8) {
                    Text(tag)
                        .font(.system(size: 12, weight: .semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(accent.opacity(0.18))
                        .clipShape(Capsule())
                        .foregroundColor(accent)

                    Text(periodLabel)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(Theme.ColorToken.textSecondary)

                    Spacer()

                    // Chevron disclosure
                    Image(systemName: "chevron.right")
                        .foregroundColor(Theme.ColorToken.textSecondary.opacity(0.8))
                        .font(.system(size: 12))
                }
            }
        }
        .transition(.opacity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(tag) \(delta != nil ? String(format: "%.1f", abs(delta!)) : "no data") pounds in \(periodLabel)")
    }
}

/// Recap Row - Three metrics in single row (Net Δ | Streak | Entries)
/// Per Stacked v1.2 spec: Mint surface with opt-out icon
struct RecapRow: View {
    let netDelta: Double   // Signed across 30d
    let bestStreak: Int    // Days
    let entries: Int       // Total entries
    let onHide: () -> Void // Hide callback

    private var netText: String {
        let tag = netDelta < 0 ? "LOST" : (netDelta > 0 ? "GAINED" : "FLAT")
        return "\(tag) \(String(format: "%.1f", abs(netDelta))) lbs"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Top row: eye.slash icon (top-left)
            HStack {
                Button(action: onHide) {
                    Image(systemName: "eye.slash")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Theme.ColorToken.textSecondary)
                        .frame(width: 44, height: 44)  // Apple HIG tap target
                }
                .buttonStyle(.plain)

                Spacer()
            }

            // Metrics row
            HStack(spacing: 12) {
                // Net delta
                Label(netText, systemImage: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(Theme.ColorToken.textPrimary)

                Spacer()

                // Best streak
                Label("\(bestStreak)‑day streak", systemImage: "flame")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(Theme.ColorToken.textPrimary)

                Spacer()

                // Total entries
                Label("\(entries) entries", systemImage: "square.and.pencil")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(Theme.ColorToken.textPrimary)
            }
        }
        .padding(16)
        .background(
            // Temporary: Simple styling until v1.2 implemented (Layer 4)
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Theme.ColorToken.surfaceMint)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Theme.ColorToken.strokeLight, lineWidth: 1)
                )
        )
    }
}

/// Did You Know Banner - Optional educational micro-tip
/// Per Stacked v1.2 spec: Mint surface with opt-out icon
struct DidYouKnowBanner: View {
    let text: String
    let onHide: () -> Void  // Hide callback

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Top row: eye.slash icon (top-left)
            HStack {
                Button(action: onHide) {
                    Image(systemName: "eye.slash")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Theme.ColorToken.textSecondary)
                        .frame(width: 44, height: 44)  // Apple HIG tap target
                }
                .buttonStyle(.plain)

                Spacer()
            }

            // Tip content
            HStack(spacing: 12) {
                Image(systemName: "lightbulb")
                    .foregroundColor(Theme.ColorToken.accentInfo)
                    .font(.system(size: 16))

                Text(text)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(Theme.ColorToken.textPrimary)

                Spacer()
            }
        }
        .padding(16)
        .background(
            // Temporary: Simple styling until v1.2 implemented (Layer 4)
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Theme.ColorToken.surfaceMint)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Theme.ColorToken.strokeLight, lineWidth: 1)
                )
        )
    }
}

// MARK: - Legacy TrendCard (Keep for backward compatibility)

struct TrendCard: View {
    let title: String
    let trend: (amount: Double, isLoss: Bool)?

    var body: some View {
        VStack(spacing: 8) {
            if let trend = trend {
                // Top: Celebration emoji (EXCITING!)
                Text(trendEmoji(for: trend))
                    .font(.system(size: 40))
                    .padding(.top, 8)

                // Middle: HUGE number + lbs (IMPACTFUL!)
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(String(format: "%.1f", trend.amount))
                        .font(.system(size: 60, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                    Text("lbs")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))
                }

                // Status pill (like weight lost pill!)
                Text(trend.isLoss ? "LOST" : "GAINED")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.3))
                    )

                // Period label (clear but subtle)
                Text(title)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.bottom, 4)
            } else {
                // No data state
                Text("📊")
                    .font(.system(size: 40))
                    .padding(.top, 8)

                Text("--")
                    .font(.system(size: 60, weight: .heavy, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))

                Text("NO DATA")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.2))
                    )

                Text(title)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.bottom, 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .padding(.horizontal, 16)  // Internal padding for content breathing room
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(cardGradient)
        )
        .shadow(color: shadowColor, radius: 8, x: 0, y: 4)
    }

    /// Luxury gradient background per Theme.ColorToken design system
    /// Loss: Emerald green gradient (success)
    /// Gain: Orange/red gradient (caution/warning)
    /// Per UI/UX spec: Deep navy background, gold highlights, green for success
    private var cardGradient: LinearGradient {
        guard let trend = trend else {
            // No data: Gray gradient
            return LinearGradient(
                colors: [Color.gray.opacity(0.6), Color.gray.opacity(0.4)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        if trend.isLoss {
            // Loss: Emerald gradient per luxury UI spec
            // Using accentPrimary (emerald #1ABC9C) for success states
            return LinearGradient(
                colors: [Theme.ColorToken.accentPrimary, Theme.ColorToken.accentPrimary.opacity(0.7)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            // Gain: Warning/Error gradient per luxury UI spec
            // Using stateWarning (amber) for gentle caution
            return LinearGradient(
                colors: [Theme.ColorToken.stateWarning, Theme.ColorToken.stateWarning.opacity(0.7)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    /// Shadow color matches card gradient per luxury UI spec
    private var shadowColor: Color {
        guard let trend = trend else {
            return Color.gray.opacity(0.3)
        }

        if trend.isLoss {
            // Loss: Emerald shadow for success
            return Theme.ColorToken.accentPrimary.opacity(0.3)
        } else {
            // Gain: Amber shadow for caution
            return Theme.ColorToken.stateWarning.opacity(0.3)
        }
    }

    /// Dynamic emoji based on trend - CELEBRATION!
    private func trendEmoji(for trend: (amount: Double, isLoss: Bool)) -> String {
        if trend.isLoss {
            // Celebration emojis for weight loss!
            switch trend.amount {
            case 0..<1:
                return "👍"  // Small progress
            case 1..<2:
                return "💪"  // Good progress
            case 2..<3:
                return "⭐️"  // Great progress
            case 3..<5:
                return "🔥"  // Excellent progress
            case 5..<10:
                return "🏆"  // Amazing progress
            default:
                return "🚀"  // Incredible progress!
            }
        } else {
            // Gentle supportive emojis for weight gain
            switch trend.amount {
            case 0..<1:
                return "💧"  // Just water weight
            case 1..<2:
                return "🤝"  // Small fluctuation
            case 2..<5:
                return "💙"  // Keep going
            default:
                return "🫂"  // Still on the journey
            }
        }
    }
}

