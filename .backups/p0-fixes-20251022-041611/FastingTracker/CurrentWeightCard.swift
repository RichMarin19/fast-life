import SwiftUI

// MARK: - Current Weight Card

struct CurrentWeightCard: View {
    @ObservedObject var weightManager: WeightManager
    let weightGoal: Double
    @Binding var showingGoalEditor: Bool
    @Binding var showingAddWeight: Bool
    @Binding var showingTrends: Bool

    /// Calculates total weight change from START (first entry) to CURRENT (latest entry)
    /// Returns: (totalChange: Double, isLoss: Bool)
    /// Positive = loss, Negative = gain
    private func calculateTotalProgress() -> (amount: Double, isLoss: Bool)? {
        guard weightManager.weightEntries.count >= 2 else { return nil }

        // Get FIRST entry (start weight from onboarding)
        let sortedEntries = weightManager.weightEntries.sorted { $0.date < $1.date }
        guard let startWeight = sortedEntries.first?.weight,
              let currentWeight = sortedEntries.last?.weight else {
            return nil
        }

        let change = startWeight - currentWeight
        return (amount: abs(change), isLoss: change > 0)
    }

    /// Returns celebration emoji based on weight loss amount (in pounds internally)
    /// More loss = more exciting emoji! 🎉
    private func celebrationEmoji(for lbs: Double) -> String {
        switch lbs {
        case 0..<1:      return "👍"  // Small loss
        case 1..<2:      return "💪"  // Good loss
        case 2..<3:      return "🌟"  // Great loss
        case 3..<5:      return "🎉"  // Excellent loss
        case 5..<10:     return "🏆"  // Amazing loss
        default:         return "🚀"  // Incredible loss!
        }
    }

    /// Returns gentle message for weight gain - progressively softer as gain increases (in pounds internally)
    /// Psychology: More gain = MORE supportive, not harsh
    private func gentleGainMessage(for lbs: Double) -> (emoji: String, message: String, color: Color) {
        switch lbs {
        case 0..<1:
            // Tiny fluctuation - totally normal
            return ("💧", "Just water weight", Color("FLPrimary"))
        case 1..<2:
            // Small gain - gentle
            return ("🤝", "Small fluctuation, you've got this", Color("FLPrimary"))
        case 2..<3:
            // Medium gain - supportive
            return ("💙", "Keep going, progress isn't always linear", .cyan)
        case 3..<5:
            // Larger gain - very supportive
            return ("🌱", "Every journey has ups and downs", Color("FLSuccess").opacity(0.7))
        default:
            // Large gain - SUPER gentle and encouraging
            return ("🫂", "You're still on the journey, one day at a time", .purple)
        }
    }

    /// Gets starting weight (first entry from onboarding)
    private func getStartWeight() -> Double? {
        guard weightManager.weightEntries.count >= 1 else { return nil }
        let sortedEntries = weightManager.weightEntries.sorted { $0.date < $1.date }
        return sortedEntries.first?.weight
    }

    /// Calculates weight remaining to reach goal
    private func calculateWeightToGo() -> Double? {
        guard weightManager.weightEntries.count >= 1, weightGoal > 0 else { return nil }
        let sortedEntries = weightManager.weightEntries.sorted { $0.date < $1.date }
        guard let currentWeight = sortedEntries.last?.weight else { return nil }
        let remaining = currentWeight - weightGoal
        return remaining > 0 ? remaining : 0
    }

    /// Calculates progress percentage toward goal weight
    /// Formula: (Starting Weight - Current Weight) / (Starting Weight - Goal Weight) × 100
    /// Returns nil if insufficient data or goal not set
    private func calculateProgressPercentage() -> Double? {
        // Require goal weight to be set
        guard weightGoal > 0 else { return nil }

        // Need at least 2 entries (start and current)
        guard weightManager.weightEntries.count >= 2 else { return nil }

        // Get starting weight (earliest entry) and current weight (latest entry)
        let sortedEntries = weightManager.weightEntries.sorted { $0.date < $1.date }
        guard let startingWeight = sortedEntries.first?.weight,
              let currentWeight = sortedEntries.last?.weight else {
            return nil
        }

        // Calculate progress
        let totalWeightToLose = startingWeight - weightGoal
        let weightLostSoFar = startingWeight - currentWeight

        // Only show progress if:
        // 1. User is trying to lose weight (start > goal)
        // 2. Some progress has been made (current != start)
        // 3. Haven't already passed the goal
        guard totalWeightToLose > 0,
              weightLostSoFar > 0,
              currentWeight > weightGoal else {
            return nil
        }

        let percentage = (weightLostSoFar / totalWeightToLose) * 100.0

        // Cap at 100% even if they've made more progress than expected
        return min(percentage, 100.0)
    }

    var body: some View {
        VStack(spacing: 8) {
            if let latest = weightManager.latestWeight {
                // TAPPABLE Current Weight Section - opens Add Weight sheet
                // Per Apple HIG: "Let people interact with content in ways they find most natural"
                // Reference: https://developer.apple.com/design/human-interface-guidelines/gestures
                // REFACTORED: Removed "Current Weight" label - now provided by UniversalCardContainer header
                // Industry Pattern: Pure content component (Apple Health, Spotify)
                VStack(spacing: 6) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(weightManager.displayWeight(for: latest), specifier: "%.1f")")
                            .font(DSTypography.displayXL)
                            .foregroundColor(Color("FLPrimary"))
                        Text("lbs")
                            .font(.title2)
                            .foregroundColor(Color("FLSuccess"))
                    }

                    Text(latest.date, style: .date)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .contentShape(Rectangle())  // Make entire area tappable
                .onTapGesture {
                    showingAddWeight = true
                }

                // Motivation Banner - LUXURY BRAND STYLE
                // Shows progress message in brand emerald style
                // Per spec: 10% accent.primary opacity, clean line icons, no emojis
                // Reference: FastLIFe_WeightTracker_Consolidated_Spec.md §4
                if let progress = calculateTotalProgress() {
                    MotivationBanner(
                        message: progress.isLoss
                            ? "You've lost \((progress.amount), default: "%.1f") lbs - keep it up!"
                            : "Progress isn't always linear - you're doing great",
                        isPositive: progress.isLoss
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        AppLogger.info("🎯 Motivation Banner tapped - opening Progress Story", category: AppLogger.ui)
                        showingTrends = true
                        AppLogger.info("🎯 showingTrends set to true", category: AppLogger.ui)
                    }
                    .padding(.top, 8)
                }

                // Goal Badge - LUXURY BRAND STYLE
                // Clean, premium badge with flag icon (no emojis, no gear)
                // Per spec: 15% accent.primary opacity, 1.5pt border, 10pt corners
                // Reference: FastLIFe_WeightTracker_Consolidated_Spec.md §5
                if weightGoal > 0 {
                    Divider()
                        .padding(.vertical, 4)

                    // Entire badge is tappable - opens goal editor
                    Button(action: {
                        showingGoalEditor = true
                    }) {
                        GoalBadge(goalText: "\(Int(weightGoal)) lbs")
                    }
                    .buttonStyle(.plain)  // Removes default button styling

                    // Progress Ring - Beautiful circular visual progress indicator
                    // Inspired by milestone concept with sexy color scheme
                    // Per Apple HIG: "Use visual metaphors to communicate meaning"
                    if let progressPercentage = calculateProgressPercentage(),
                       let progress = calculateTotalProgress(),
                       let startWeight = getStartWeight(),
                       let weightToGo = calculateWeightToGo() {
                        CircularProgressRing(
                            percentage: progressPercentage,
                            weightLost: progress.amount,
                            weightToGo: weightToGo,
                            startWeight: startWeight,
                            goalWeight: weightGoal
                        )
                        .padding(.top, 8)
                    }
                }

                if let bmi = latest.bmi {
                    HStack(spacing: 16) {
                        VStack {
                            Text("BMI")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(bmi, specifier: "%.1f")")
                                .font(.headline)
                        }

                        if let bodyFat = latest.bodyFat {
                            VStack {
                                Text("Body Fat")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("\(bodyFat, specifier: "%.1f")%")
                                    .font(.headline)
                            }
                        }
                    }
                    .padding(.top, 8)
                }
            }
        }
        // REMOVED: Styling now provided by UniversalCardContainer wrapper
        // - .frame(maxWidth: .infinity) → provided by wrapper
        // - .padding() → provided by wrapper (Theme.Spacing.pad)
        // - .background() → provided by wrapper (Theme.ColorToken.card)
        // - .cornerRadius() → provided by wrapper (Theme.Radius.card)
        // - .shadow() → provided by wrapper (Theme.ColorToken.shadowCard)
    }
}

// MARK: - Circular Progress Ring (Milestone Style)

/// Beautiful circular progress indicator inspired by milestone design
/// Blue→Green gradient shows progression visually
/// Per Apple HIG: "Use visual metaphors to make abstract concepts tangible"
/// Reference: https://developer.apple.com/design/human-interface-guidelines/charts
struct CircularProgressRing: View {
    let percentage: Double
    let weightLost: Double
    let weightToGo: Double?
    let startWeight: Double?
    let goalWeight: Double

    var body: some View {
        VStack(spacing: 16) {
            // Title
            Text("Your Progress Journey")
                .font(DSTypography.displayM)
                .foregroundColor(.primary)

            // Circular Progress Ring (WIDER!)
            ZStack {
                // Background circle (gray)
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 14)
                    .frame(width: 200, height: 200)

                // Progress arc (BLUE → GREEN gradient - shows progression!)
                Circle()
                    .trim(from: 0, to: CGFloat(percentage / 100))
                    .stroke(
                        AngularGradient(
                            colors: [Color("FLPrimary"), Color.cyan, Color("FLSuccess")],
                            center: .center,
                            startAngle: .degrees(0),
                            endAngle: .degrees(360 * (percentage / 100))
                        ),
                        style: StrokeStyle(lineWidth: 14, lineCap: .round)
                    )
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: percentage)

                // Center content
                VStack(spacing: 4) {
                    // Milestone emoji (dynamic based on percentage)
                    Text(milestoneEmoji(for: percentage))
                        .font(DSTypography.displayL)

                    // Large percentage
                    Text("\(percentage, specifier: "%.0f")%")
                        .font(DSTypography.displayXLRounded)
                        .foregroundColor(progressColor(for: percentage))

                    // "COMPLETE" label
                    Text("COMPLETE")
                        .font(DSTypography.statLabel)
                        .foregroundColor(.secondary)
                        .tracking(1)
                }
            }

            // Stats below ring
            HStack(spacing: 24) {
                // Weight Lost (left)
                VStack(spacing: 2) {
                    Text("\((weightLost), specifier: "%.1f") \("lbs")")
                        .font(DSTypography.statValueSmall)
                        .foregroundColor(Color("FLSuccess"))
                    Text("LOST")
                        .font(DSTypography.listCaption)
                        .foregroundColor(.secondary)
                        .tracking(0.5)
                }

                // Divider
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 1, height: 35)

                // Weight To Go (right)
                if let toGo = weightToGo, toGo > 0 {
                    VStack(spacing: 2) {
                        Text("\((toGo), specifier: "%.1f") \("lbs")")
                            .font(DSTypography.statValueSmall)
                            .foregroundColor(.orange)
                        Text("TO GO")
                            .font(DSTypography.listCaption)
                            .foregroundColor(.secondary)
                            .tracking(0.5)
                    }
                }
            }

            // 10 Milestone Dots (like Image 2!)
            VStack(spacing: 8) {
                // Dots row
                HStack(spacing: 12) {
                    ForEach(1...10, id: \.self) { milestone in
                        Circle()
                            .fill(milestoneColor(for: milestone, percentage: percentage))
                            .frame(width: 20, height: 20)
                            .overlay(
                                Circle()
                                    .strokeBorder(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                    }
                }

                // Progress text
                Text("\(milestonesCompleted(for: percentage)) OF 10 MILESTONES COMPLETE")
                    .font(DSTypography.statLabel)
                    .foregroundColor(.secondary)
                    .tracking(0.5)
            }
            .padding(.top, 8)
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 24)
    }

    /// Returns motivational emoji based on progress percentage
    private func milestoneEmoji(for percentage: Double) -> String {
        switch percentage {
        case 0..<10:    return "🌱"
        case 10..<25:   return "💪"
        case 25..<50:   return "⭐️"
        case 50..<75:   return "🔥"
        case 75..<90:   return "🏆"
        case 90..<100:  return "🚀"
        default:        return "👑"
        }
    }

    /// Returns color for percentage text based on progress
    private func progressColor(for percentage: Double) -> Color {
        switch percentage {
        case 0..<33:    return Color("FLPrimary")
        case 33..<66:   return .cyan
        default:        return .green
        }
    }

    /// Returns how many milestones are completed (0-10)
    private func milestonesCompleted(for percentage: Double) -> Int {
        return Int((percentage / 100) * 10)
    }

    /// Returns color for each milestone dot matching the ring's gradient
    /// Creates smooth blue → cyan → green progression like the circular ring
    private func milestoneColor(for milestone: Int, percentage: Double) -> Color {
        let completed = milestonesCompleted(for: percentage)

        if milestone <= completed {
            // Filled dots: smooth gradient matching ring (blue → cyan → green)
            // Distribute colors evenly across 10 milestones
            switch milestone {
            case 1...3:
                return Color("FLPrimary")
            case 4...6:
                return .cyan
            case 7...10:
                return .green
            default:
                return Color("FLPrimary")
            }
        } else {
            // Empty dots: light gray
            return Color.gray.opacity(0.2)
        }
    }
}

// MARK: - Motivation Banner (Luxury Brand Style)

/// Motivation Banner - Brand-tinted emerald style per North Star spec
/// Reference: FastLIFe_WeightTracker_Consolidated_Spec.md §4
/// No emojis - uses clean SF Symbol line icons
struct MotivationBanner: View {
    let message: String
    let isPositive: Bool

    var body: some View {
        HStack(spacing: 12) {
            // SF Symbol placeholder for progress wave/spark icon (2pt stroke equivalent)
            // Replace with custom ic_progress_wave when available
            Image(systemName: isPositive ? "chart.line.uptrend.xyaxis" : "heart.fill")
                .renderingMode(.template)
                .foregroundColor(Theme.ColorToken.accentPrimary)
                .font(DSTypography.displayS)

            Text(message)
                .font(DSTypography.cardTitle)
                .foregroundColor(Theme.ColorToken.accentPrimary)

            Spacer(minLength: 0)
        }
        .padding(14)
        .background(
            Theme.ColorToken.card
                .overlay(Theme.ColorToken.accentPrimary.opacity(0.10))
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: Theme.ColorToken.shadowCard, radius: 10, x: 0, y: 6)
        .accessibilityLabel(Text("Motivation: \(message)"))
    }
}

// MARK: - Goal Badge (Luxury Brand Style)

/// Goal Badge - Clean premium badge per North Star spec
/// Reference: FastLIFe_WeightTracker_Consolidated_Spec.md §5
/// No emojis, no gear icon - just clean flag icon and goal text
struct GoalBadge: View {
    let goalText: String  // e.g., "150 lbs"

    var body: some View {
        HStack(spacing: 10) {
            // SF Symbol placeholder for flag/arrow-to-goal icon (24pt, 2pt stroke equivalent)
            // Replace with custom ic_goal_flag when available
            Image(systemName: "flag.fill")
                .renderingMode(.template)
                .foregroundColor(Theme.ColorToken.accentPrimary)
                .font(DSTypography.displayS)

            Text("GOAL: \(goalText)")
                .font(DSTypography.statValueSmall)
                .foregroundColor(Theme.ColorToken.accentPrimary)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Theme.ColorToken.accentPrimary, lineWidth: 1.5)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Theme.ColorToken.accentPrimary.opacity(0.15))
                )
        )
    }
}
