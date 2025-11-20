import SwiftUI

/// Insights placeholder card while expanded micro-lessons are prepared.
struct WeightControlCenterInsightsCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.cardPadding) {
            Text("Smart tips based on your trends.")
                .font(DSTypography.listTitle)
                .foregroundColor(Theme.ColorToken.textSecondaryOnDark)
        }
    }
}
