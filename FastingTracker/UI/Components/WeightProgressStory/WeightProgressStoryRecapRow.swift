import SwiftUI

struct RecapRow: View {
    let netDelta: Double   // Signed across 30d
    let bestStreak: Int    // Days
    let entries: Int       // Total entries
    let onHide: () -> Void // Hide callback

    // v1.2b: Track best streak in @AppStorage for badge system
    @AppStorage("weight_tracker_best_streak") private var savedBestStreak: Int = 0
    @State private var showNewBestBadge = false  // Badge animation state

    private var netText: String {
        let tag = netDelta < 0 ? "LOST" : (netDelta > 0 ? "GAINED" : "FLAT")
        return "\(tag) \(String(format: "%.1f", abs(netDelta))) lbs"
    }

    /// Check if current streak is new best
    /// Per v1.2 spec D.2: New best streak → small badge dot + haptic .success
    private var isNewBest: Bool {
        return bestStreak > savedBestStreak && bestStreak > 0
    }

    var body: some View {
        DSBanner(ice: onHide) {
            // Metrics row (2 metrics: Net Delta + Streak)
            // 🔧 FIX #20: Add top padding to push content down, DSBanner already provides 16pt horizontal (side) padding
            HStack(spacing: DSSpacing.cardElementSpacing) {
                // Net delta
                Label(netText, systemImage: "chart.line.uptrend.xyaxis")
                    .font(DSTypography.statValueSmall)
                    .foregroundColor(Theme.ColorToken.textPrimary)

                Spacer()

                // Best streak (v1.2b: with badge dot when new best achieved)
                ZStack(alignment: .topTrailing) {
                    Label("\(bestStreak)‑day streak", systemImage: "flame.fill")
                        .font(DSTypography.statValueSmall)
                        .foregroundColor(Theme.ColorToken.textPrimary)

                    // NEW BEST BADGE (v1.2b) - Small dot overlay when new best streak achieved
                    // Per v1.2 spec D.2: Badge dot + haptic .success
                    if isNewBest {
                        Circle()
                            .fill(Theme.ColorToken.stateSuccess)
                            .frame(width: 8, height: 8)
                            .offset(x: 6, y: -4)
                            .opacity(showNewBestBadge ? 1.0 : 0.0)
                            .scaleEffect(showNewBestBadge ? 1.0 : 0.5)
                            .animation(.spring(response: 0.5, dampingFraction: 0.6), value: showNewBestBadge)
                    }
                }
            }
            .padding(.top, 24)  // 🔧 FIX #20: 24pt top padding pushes content down, leaving 16pt bottom space (66pt - 24pt top - ~26pt content = 16pt bottom)
        }
        .onAppear {
            // v1.2b: Check for new best streak and trigger badge animation + haptic feedback
            if isNewBest {
                // Update saved best streak
                savedBestStreak = bestStreak

                // Trigger badge animation
                showNewBestBadge = true

                // Haptic .success feedback (per spec D.2)
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
        }
    }
}

/// Reflection Nudge - Behavioral prompt for micro-planning (v1.2b)
/// Per v1.2 spec D.3: Below 30-day card, rotate one line at random
/// Tap → triggers micro-plan Coach prompt (stub now, functional later)
/// v1.2e: Refactored to use DSBanner component for uniform container sizing
/// 🔧 FIX #7: Accepts pre-computed prompt text to prevent random changes during drag
