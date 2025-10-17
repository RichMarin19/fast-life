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

    // Opt-out system: Shared manager accessible from anywhere
    @ObservedObject private var optOutManager = ContentOptOutManager.shared

    // Unique ID for this content
    private let contentID = "progress_story_trends_v1"

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

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Motivational header with emoji
                    // Per Apple HIG: Use large titles for top-level information
                    VStack(spacing: 8) {
                        Text("📈 Your Progress Story")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)

                        Text("See how far you've come!")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 8)

                    // Trends Grid - HANDOFF.md pattern: Container padding ONLY
                    // CRITICAL: Equal spacing on both sides (20pt each)
                    // ScrollView adds default contentInset - must be explicitly zeroed
                    VStack(spacing: 16) {
                        // Row 1: 7 days and 30 days
                        HStack(spacing: 16) {
                            TrendCard( title: "7 DAYS", trend: calculateTrend(days: 7))
                            TrendCard( title: "30 DAYS", trend: calculateTrend(days: 30))
                        }

                        // Row 2: 90 days and All Time
                        HStack(spacing: 16) {
                            TrendCard( title: "90 DAYS", trend: calculateTrend(days: 90))
                            TrendCard( title: "ALL TIME", trend: calculateTrend(days: nil))
                        }
                    }
                    .padding(.horizontal, 20)
                    .frame(maxWidth: .infinity, alignment: .leading)  // Force full width alignment
                }
                .padding(.vertical)
                .frame(maxWidth: .infinity)  // Ensure VStack fills entire ScrollView width
            }
            .contentMargins(.horizontal, 0, for: .scrollContent)  // iOS 17+ removes ScrollView default margins
            .navigationTitle("Weight Trends")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    // LUXURY OPT-OUT BUTTON (v1.0 - Refined Design)
                    // Per UI/UX Design Note: FastLIFe_UIUX_DontShowAgain_DesignNote.md
                    // Layers: Gradient border + Fade animation + Haptic feedback
                    Button {
                        // Layer 3: Haptic feedback (light tap) = premium responsiveness
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()

                        // Opt out content
                        optOutManager.optOutContent(id: contentID, category: .progressSummaries, text: "Your Progress Story")

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

