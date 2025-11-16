import SwiftUI
import Foundation

// MARK: - Current Weight Card

struct CurrentWeightCard: View {
    @ObservedObject var weightManager: WeightManager
    let weightGoal: Double
    @Binding var showingGoalEditor: Bool
    @Binding var showingAddWeight: Bool
    @Binding var showingTrends: Bool
    @ObservedObject var measurementObserver: MeasurementSystemObserver = MeasurementSystemObserver.shared

    // MARK: - Helpers

    private var unitAbbreviation: String {
        weightManager.currentUnitAbbreviation
    }

    /// Calculates total weight change from START (first entry) to CURRENT (latest entry)
    /// Returns: (totalChange: Double, isLoss: Bool)
    /// Positive = loss, Negative = gain
    private func calculateTotalProgress() -> (amount: Double, isLoss: Bool)? {
        guard let start = weightManager.resolvedStartWeight()?.weight,
              let current = weightManager.latestWeight?.weight else {
            return nil
        }

        let change = start - current
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
        return weightManager.resolvedStartWeight()?.weight
    }

    /// Calculates weight remaining to reach goal
    // PHASE 1 FIX (Task 1.4): Defensive logging - alert when calculation fails
    private func calculateWeightToGo() -> Double? {
        guard weightManager.weightEntries.count >= 1, weightGoal > 0 else {
            AppLogger.debug("⚠️ Cannot calculate weight to go - entries: \(weightManager.weightEntries.count), goal: \(weightGoal)", category: AppLogger.ui)
            return nil
        }
        let sortedEntries = weightManager.weightEntries.sorted { $0.date < $1.date }
        guard let currentWeight = sortedEntries.last?.weight else {
            AppLogger.warning("⚠️ Cannot calculate weight to go - no current weight after sorting", category: AppLogger.ui)
            return nil
        }
        let remaining = currentWeight - weightGoal
        return remaining > 0 ? remaining : 0
    }

    private func bodyFatAccessibilityText(bmi: Double, bodyFat: Double?) -> String {
        if let bodyFat {
            return "BMI \(String(format: "%.1f", bmi)), body fat \(String(format: "%.1f", bodyFat)) percent"
        }
        return "BMI \(String(format: "%.1f", bmi))"
    }

    /// Calculates progress percentage toward goal weight
    var body: some View {
        let _ = measurementObserver.system
        let progressPercentage = weightManager.progressPercentage(toward: weightGoal)
        let hasPositiveProgress = (progressPercentage ?? 0) > 0.0001

        VStack(spacing: 8) {
            if let latest = weightManager.latestWeight {
                // TAPPABLE Current Weight Section - opens Add Weight sheet
                // Per Apple HIG: "Let people interact with content in ways they find most natural"
                // Reference: https://developer.apple.com/design/human-interface-guidelines/gestures
                // REFACTORED: Removed "Current Weight" label - now provided by UniversalCardContainer header
                // Industry Pattern: Pure content component (Apple Health, Spotify)
                VStack(spacing: 6) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(weightManager.formattedDisplayWeight(latest.weight))
                            .font(DSTypography.displayXL)
                            .dynamicTypeSize(.large ... .xxxLarge)
                            .foregroundColor(Color("FLPrimary"))
                        Text(unitAbbreviation)
                            .font(.title2)
                            .dynamicTypeSize(.large ... .xxLarge)
                            .foregroundColor(Color("FLSuccess"))
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Current weight \(weightManager.formattedDisplayWeight(latest.weight)) \(unitAbbreviation)")

                    Text(latest.date, style: .date)
                        .font(.subheadline)
                        .dynamicTypeSize(.large ... .xxLarge)
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
                        message: hasPositiveProgress
                            ? "You've lost \(weightManager.formattedDisplayWeight(progress.amount)) \(unitAbbreviation) - keep it up!"
                            : "Progress isn't always linear - you're doing great",
                        isPositive: hasPositiveProgress
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
                        GoalBadge(goalText: "\(weightManager.formattedDisplayWeight(weightGoal)) \(unitAbbreviation)")
                    }
                    .buttonStyle(.plain)  // Removes default button styling

                    // Progress Ring - Beautiful circular visual progress indicator
                    // Inspired by milestone concept with sexy color scheme
                    // Per Apple HIG: "Use visual metaphors to communicate meaning"
                    if let progressPercentage,
                       let progress = calculateTotalProgress(),
                       let startWeight = getStartWeight(),
                       let weightToGo = calculateWeightToGo() {
                        let weightChangeDisplay = weightManager.formattedDisplayWeight(progress.amount)
                        let weightToGoDisplay = weightManager.formattedDisplayWeight(weightToGo)
                        let weightChangeLabel = hasPositiveProgress ? "LOST" : "GAINED"
                        let weightChangeColor = hasPositiveProgress ? Theme.ColorToken.stateSuccess : Theme.ColorToken.accentCoral
                        let effectivePercentage = hasPositiveProgress ? progressPercentage : 0.0

                        CircularProgressRing(
                            percentage: effectivePercentage,
                            weightChangeText: weightChangeDisplay,
                            weightChangeLabel: weightChangeLabel,
                            weightChangeColor: weightChangeColor,
                            weightToGoText: weightToGo > 0 ? weightToGoDisplay : nil,
                            unitAbbreviation: unitAbbreviation,
                            startWeight: startWeight,
                            goalWeight: weightGoal,
                            milestoneCount: weightManager.milestoneCount
                        )
                        .padding(.top, 8)
                    }
                }

                if let bmi = latest.bmi {
                    HStack(spacing: 16) {
                        VStack {
                            Text("BMI")
                                .font(.caption)
                                .dynamicTypeSize(.large ... .xxLarge)
                                .foregroundColor(.secondary)
                            Text("\(bmi, specifier: "%.1f")")
                                .font(.headline)
                                .dynamicTypeSize(.large ... .xxLarge)
                        }

                        if let bodyFat = latest.bodyFat {
                            VStack {
                                Text("Body Fat")
                                    .font(.caption)
                                    .dynamicTypeSize(.large ... .xxLarge)
                                    .foregroundColor(.secondary)
                                Text("\(bodyFat, specifier: "%.1f")%")
                                    .font(.headline)
                                    .dynamicTypeSize(.large ... .xxLarge)
                            }
                        }
                    }
                    .padding(.top, 8)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(bodyFatAccessibilityText(bmi: bmi, bodyFat: latest.bodyFat))
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
    let weightChangeText: String
    let weightChangeLabel: String
    let weightChangeColor: Color
    let weightToGoText: String?
    let unitAbbreviation: String
    let startWeight: Double?
    let goalWeight: Double
    let milestoneCount: Int

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
                    .stroke(Color.gray.opacity(0.2), lineWidth: DSSpacing.progressRingStrokeWidth)
                    .frame(width: DSSpacing.progressRingSize, height: DSSpacing.progressRingSize)

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
                        style: StrokeStyle(lineWidth: DSSpacing.progressRingStrokeWidth, lineCap: .round)
                    )
                    .frame(width: DSSpacing.progressRingSize, height: DSSpacing.progressRingSize)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: percentage)

                // Center content
                VStack(spacing: 4) {
                    // Milestone emoji (dynamic based on percentage)
                    Text(milestoneEmoji(for: percentage))
                        .font(DSTypography.displayL)

                    // Large percentage
                    Text("\(Int(round(percentage)))%")
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
                    Text("\(weightChangeText) \(unitAbbreviation)")
                        .font(DSTypography.statValueSmall)
                        .foregroundColor(weightChangeColor)
                    Text(weightChangeLabel.uppercased())
                        .font(DSTypography.listCaption)
                        .foregroundColor(.secondary)
                        .tracking(0.5)
                }

                // Divider
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 1, height: 35)

                // Weight To Go (right)
                if let toGoText = weightToGoText {
                    VStack(spacing: 2) {
                        Text("\(toGoText) \(unitAbbreviation)")
                            .font(DSTypography.statValueSmall)
                            .foregroundColor(.orange)
                        Text("TO GO")
                            .font(DSTypography.listCaption)
                            .foregroundColor(.secondary)
                            .tracking(0.5)
                    }
                }
            }

            if milestoneCount > 0 {
                let completed = milestonesCompleted(for: percentage, total: milestoneCount)

                VStack(spacing: 8) {
                    HStack(spacing: 12) {
                        ForEach(0..<milestoneCount, id: \.self) { index in
                            Circle()
                                .fill(milestoneColor(for: index, total: milestoneCount, completed: completed))
                                .frame(width: DSSpacing.milestoneDotSize, height: DSSpacing.milestoneDotSize)
                                .overlay(
                                    Circle()
                                        .strokeBorder(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                        }
                    }

                    Text("\(completed) OF \(milestoneCount) MILESTONES COMPLETE")
                        .font(DSTypography.statLabel)
                        .foregroundColor(.secondary)
                        .tracking(0.5)
                }
                .padding(.top, 8)
            }
        }
        .padding(.vertical, DSSpacing.progressRingPaddingVertical)
        .padding(.horizontal, DSSpacing.progressRingPaddingHorizontal)
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

    /// Returns how many milestones are completed based on total count
    private func milestonesCompleted(for percentage: Double, total: Int) -> Int {
        guard total > 0 else { return 0 }
        return Int((percentage / 100) * Double(total))
    }

    /// Returns color for each milestone dot using a simple gradient based on position
    private func milestoneColor(for index: Int, total: Int, completed: Int) -> Color {
        guard index < total else { return Color.gray.opacity(0.2) }

        if index < completed {
            let ratio = total > 1 ? Double(index) / Double(max(total - 1, 1)) : 1
            switch ratio {
            case ..<0.33:
                return Color("FLPrimary")
            case ..<0.66:
                return .cyan
            default:
                return .green
            }
        } else {
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
                .dynamicTypeSize(.large ... .xxLarge)

            Text("GOAL: \(goalText)")
                .font(DSTypography.statValueSmall)
                .dynamicTypeSize(.large ... .xxLarge)
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
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Goal weight \(goalText)")
    }
}
