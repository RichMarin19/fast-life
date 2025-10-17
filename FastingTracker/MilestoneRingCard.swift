import SwiftUI

// MARK: - Milestone Ring Card (Luxury North Star)

/// Milestone Ring Card - Luxury progress visualization per North Star spec
/// Reference: FastLIFe_WeightTracker_Consolidated_Spec.md §6
/// Shows circular progress to next milestone with timeline dots below
/// Industry Standard: Apple Health-style progress rings with premium styling
struct MilestoneRingCard: View {
    // MARK: - Properties

    var progress: CGFloat           // 0...1 to next milestone
    var milestoneIndex: Int         // e.g., 6
    var centerValue: String         // e.g., "159.9"
    var dateText: String            // e.g., "Aug 24, 2024"
    var leftStat: String            // e.g., "163.0 (1y ago)"
    var midStat: String             // e.g., "18% complete"
    var rightStat: String           // e.g., "3.1 to go"
    var totalMilestones: Int        // Total milestone count
    var completedMilestones: Int    // How many completed

    // MARK: - Accessibility

    @Environment(\.accessibilityReduceMotion) var reduceMotion

    // MARK: - Body

    var body: some View {
        VStack(spacing: 14) {
            // Title: "MILESTONE 6"
            Text("MILESTONE \(milestoneIndex)")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Theme.ColorToken.textSecondary)

            // Circular Progress Ring
            ZStack {
                // Background ring (track)
                Circle()
                    .trim(from: 0, to: 1)
                    .stroke(
                        Theme.ColorToken.dividerDark,
                        style: StrokeStyle(lineWidth: 16, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))

                // Progress arc with glow effect
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        Theme.ColorToken.accentPrimary,
                        style: StrokeStyle(lineWidth: 16, lineCap: .round)
                    )
                    .shadow(
                        color: Theme.ColorToken.accentPrimary.opacity(0.25),
                        radius: 12,
                        x: 0,
                        y: 6
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(
                        reduceMotion ? .none : .easeInOut(duration: 0.2),
                        value: progress
                    )

                // Center content
                VStack(spacing: 4) {
                    Text(centerValue)
                        .font(.system(size: 42, weight: .semibold))
                        .foregroundColor(Theme.ColorToken.textPrimary)

                    Text(dateText)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(Theme.ColorToken.textSecondary)
                }
            }
            .frame(height: 220)

            // Trio stats below ring
            HStack {
                Text(leftStat)
                    .font(.system(size: 13))
                    .foregroundColor(Theme.ColorToken.textSecondary)

                Spacer()

                Text(midStat)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Theme.ColorToken.textPrimary)

                Spacer()

                Text(rightStat)
                    .font(.system(size: 13))
                    .foregroundColor(Theme.ColorToken.textSecondary)
            }

            // Milestone rail (timeline dots)
            HStack(spacing: 10) {
                ForEach(0..<totalMilestones, id: \.self) { i in
                    Circle()
                        .fill(
                            i < completedMilestones
                                ? Theme.ColorToken.accentPrimary
                                : Theme.ColorToken.textSecondary.opacity(0.4)
                        )
                        .frame(width: 10, height: 10)
                }
            }
        }
        .padding(16)
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
            centerValue: "159.9",
            dateText: "Aug 24, 2024",
            leftStat: "163.0 (1y ago)",
            midStat: "18% complete",
            rightStat: "3.1 to go",
            totalMilestones: 10,
            completedMilestones: 6
        )
        .padding()
    }
}
