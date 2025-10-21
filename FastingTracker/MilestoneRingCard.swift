import SwiftUI

// MARK: - Milestone Ring Card (Luxury North Star v2)

/// Milestone Ring Card - Redesigned with larger ring and reorganized layout
/// NEW LAYOUT:
/// - Top: Milestone title + opt-out eye icon (provided by DSCard)
/// - Stats row ABOVE ring (Start, Progress, To Goal)
/// - Large circular ring in center
/// - Milestone dots BELOW ring
/// Reference: FastLIFe_WeightTracker_Consolidated_Spec.md §6
/// Industry Standard: Apple Health-style progress rings with premium styling
/// v1.3b: Migrated to DSCard universal container (Phase 1 card standardization complete)
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
    let cardManager: TrackerCardManager  // Card manager for visibility control

    @State private var animateProgress: Bool = true

    // MARK: - Accessibility

    @Environment(\.accessibilityReduceMotion) var reduceMotion

    // MARK: - Body

    var body: some View {
        DSCard(
            cardType: .milestone,
            title: "Milestone \(milestoneIndex)/\(totalMilestones)",
            cardManager: cardManager
        ) {
            // PURE CONTENT - No styling! DSCard provides padding, background, shadow
            VStack(spacing: 16) {
                // LAYER 1: Stats row ABOVE ring
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

            // LAYER 2: BIGGER circular ring in center
            // v1.2d: Replaced duplicated ring code with DSProgressRing component
            // Industry Pattern: Apple Watch Activity Rings
            // Extracted to eliminate ~60-80 lines of duplication across CircularTrendRingCard + MilestoneRingCard
            ZStack {
                DSProgressRing(
                    progress: progress,
                    size: 260,
                    strokeWidth: 18,
                    progressColor: Theme.ColorToken.accentPrimary,
                    trackColor: Theme.ColorToken.dividerDark,
                    glowIntensity: 0.30,
                    enableGlow: true,
                    enableHalo: false,  // No halo for milestone ring (simpler design)
                    animationDuration: 0.25,
                    animateProgress: $animateProgress
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

                // LAYER 3: Milestone dots BELOW ring
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
        }  // DSCard provides .padding(16pt), .background(), .clipShape(), .shadow()
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
            cardManager: TrackerCardManager.shared
        )
        .padding(.horizontal, 20)
    }
}

