import SwiftUI

// MARK: - Milestone Ring Card (Luxury North Star v2)

/// Milestone Ring Card - Redesigned with larger ring and reorganized layout
/// NEW LAYOUT:
/// - Top: Milestone title + opt-out eye icon
/// - Stats row ABOVE ring (Start, Progress, To Goal)
/// - Large circular ring in center
/// - Milestone dots BELOW ring
/// Reference: FastLIFe_WeightTracker_Consolidated_Spec.md §6
/// Industry Standard: Apple Health-style progress rings with premium styling
struct MilestoneRingCard: View {
    // MARK: - Properties

    let progress: CGFloat           // 0...1 to next milestone
    let milestoneIndex: Int         // e.g., 6
    let centerValue: String         // e.g., "159.9"
    let dateText: String            // e.g., "Aug 24, 2024"
    let leftStat: String            // e.g., "Start weight"
    let midStat: String             // e.g., "Progress"
    let rightStat: String           // e.g., "34.2 to go"
    let totalMilestones: Int        // Total milestone count
    let completedMilestones: Int    // How many completed
    let onOptOut: (() -> Void)?     // Optional: Hide card callback

    // MARK: - Accessibility

    @Environment(\.accessibilityReduceMotion) var reduceMotion

    // MARK: - Body

    var body: some View {
        VStack(spacing: 16) {
            // LAYER 1: Header with title + opt-out icon
            HStack {
                // Milestone title
                Text("Milestone \(milestoneIndex)/\(totalMilestones)")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Theme.ColorToken.textPrimary)

                Spacer()

                // Opt-out eye icon (top-right)
                if let optOutAction = onOptOut {
                    Button(action: optOutAction) {
                        Image(systemName: "eye.slash")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Theme.ColorToken.textSecondary)
                    }
                    .accessibilityLabel("Hide milestone card")
                }
            }

            // LAYER 2: Stats row ABOVE ring
            HStack(spacing: 8) {
                // Left: Start
                VStack(spacing: 2) {
                    Text("Start")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Theme.ColorToken.textSecondary)
                    Text(leftStat)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Theme.ColorToken.textPrimary)
                }

                Spacer()

                // Center: Progress
                VStack(spacing: 2) {
                    Text("Progress")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Theme.ColorToken.textSecondary)
                    Text(midStat)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Theme.ColorToken.textPrimary)
                }

                Spacer()

                // Right: To Goal
                VStack(spacing: 2) {
                    Text("To Goal")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Theme.ColorToken.textSecondary)
                    Text(rightStat)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Theme.ColorToken.textPrimary)
                }
            }
            .padding(.horizontal, 8)

            // LAYER 3: BIGGER circular ring in center
            ZStack {
                // Background ring (track)
                Circle()
                    .trim(from: 0, to: 1)
                    .stroke(
                        Theme.ColorToken.dividerDark,
                        style: StrokeStyle(lineWidth: 18, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))

                // Progress arc with glow effect
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        Theme.ColorToken.accentPrimary,
                        style: StrokeStyle(lineWidth: 18, lineCap: .round)
                    )
                    .shadow(
                        color: Theme.ColorToken.accentPrimary.opacity(0.3),
                        radius: 14,
                        x: 0,
                        y: 6
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(
                        reduceMotion ? .none : .easeInOut(duration: 0.25),
                        value: progress
                    )

                // Center content
                VStack(spacing: 4) {
                    Text(centerValue)
                        .font(.system(size: 48, weight: .semibold))
                        .foregroundColor(Theme.ColorToken.textPrimary)

                    Text(dateText)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(Theme.ColorToken.textSecondary)
                }
            }
            .frame(height: 260)  // Bigger ring (was 220)

            // LAYER 4: Milestone dots BELOW ring
            VStack(spacing: 8) {
                // Progress text above dots
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Theme.ColorToken.accentPrimary)
                        .font(.system(size: 12))
                    Text("\(completedMilestones) done")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Theme.ColorToken.textSecondary)

                    Spacer()

                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Theme.ColorToken.textPrimary)
                }

                // Progress bar with dots
                HStack(spacing: 0) {
                    ForEach(0..<totalMilestones, id: \.self) { i in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                i < completedMilestones
                                    ? Theme.ColorToken.accentPrimary
                                    : Theme.ColorToken.textSecondary.opacity(0.2)
                            )
                            .frame(height: 8)
                    }
                }
            }
        }
        .padding(20)  // Generous padding for luxury feel
        .frame(maxWidth: .infinity)  // Match Current Weight card width
        .background(Theme.ColorToken.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Theme.ColorToken.shadowCard, radius: 16, x: 0, y: 8)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        // Dark background like Weight Tracker
        Color(red: 10/255, green: 18/255, blue: 36/255)
            .ignoresSafeArea()

        MilestoneRingCard(
            progress: 0.65,
            milestoneIndex: 6,
            centerValue: "184.2",
            dateText: "Oct 17, 2025",
            leftStat: "Start weight",
            midStat: "Progress",
            rightStat: "34.2 to go",
            totalMilestones: 10,
            completedMilestones: 6,
            onOptOut: {
                print("Hide milestone card")
            }
        )
        .padding(.horizontal, 20)
    }
}
