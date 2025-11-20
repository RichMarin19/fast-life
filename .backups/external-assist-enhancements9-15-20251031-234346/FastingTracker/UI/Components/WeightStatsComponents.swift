import SwiftUI

// MARK: - Weight Statistics Components

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
 .font(DSTypography.cardSubtitle)
 Text("Don't show again")
 .font(DSTypography.cardSubtitle)
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
        VStack(spacing: DSSpacing.cardElementSpacing) {
            // REMOVED: "Statistics" header - DSCard now provides title in header
            // Following Universal Standardization Architecture pattern

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: DSSpacing.cardElementSpacing) {
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
        // REMOVED: Card styling (padding, background, cornerRadius, shadow)
        // DSCard universal container now provides all standardized styling
        // Following Universal Standardization Architecture pattern
    }
}

// MARK: - Supporting Components

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: DSSpacing.cardSmallSpacing) {
            Image(systemName: icon)
                .font(DSTypography.displayS)
                .foregroundColor(color)

            Text(value)
                .font(DSTypography.statValueMedium)
                .fontWeight(.bold)

            Text(title)
                .font(DSTypography.listCaption)
                .foregroundColor(Theme.ColorToken.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        // REMOVED: .padding(), .background(), .cornerRadius() - these block parent drag gestures
        // DSCard wrapper provides all necessary styling and gesture handling
        // Per Apple docs: nested interactive views prevent gesture propagation
    }
}

struct WeightChangeStatCard: View {
    let title: String
    let weightChange: Double?

    var body: some View {
        VStack(spacing: DSSpacing.cardSmallSpacing) {
            if let change = weightChange {
                // Arrow icon based on gain/loss
                Image(systemName: change >= 0 ? "arrow.up.right" : "arrow.down.right")
                    .font(DSTypography.displayS)
                    .foregroundColor(change >= 0 ? Theme.ColorToken.stateError : Theme.ColorToken.stateSuccess)

                // Weight change value with arrow
                HStack(spacing: DSSpacing.cardExtraSmallSpacing) {
                    Text(String(format: "%.1f \("lbs")", (abs(change))))
                        .font(DSTypography.statValueMedium)
                        .fontWeight(.bold)
                    Image(systemName: change >= 0 ? "arrow.up" : "arrow.down")
                        .font(DSTypography.statValueMedium)
                        .fontWeight(.bold)
                }
                .foregroundColor(change >= 0 ? Theme.ColorToken.stateError : Theme.ColorToken.stateSuccess)
            } else {
                Image(systemName: "calendar")
                    .font(DSTypography.displayS)
                    .foregroundColor(Theme.ColorToken.textSecondary.opacity(0.6))

                Text("N/A")
                    .font(DSTypography.statValueMedium)
                    .fontWeight(.bold)
                    .foregroundColor(Theme.ColorToken.textSecondary.opacity(0.6))
            }

            Text(title)
                .font(DSTypography.listCaption)
                .foregroundColor(Theme.ColorToken.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        // REMOVED: .padding(), .background(), .cornerRadius() - these block parent drag gestures
        // DSCard wrapper provides all necessary styling and gesture handling
        // Per Apple docs: nested interactive views prevent gesture propagation
    }
}
