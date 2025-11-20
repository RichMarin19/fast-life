import SwiftUI

/// History management card within the Weight Control Center.
struct WeightControlCenterHistoryCard: View {
    @ObservedObject var viewModel: WeightControlCenterViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.cardPadding) {
            Text("Review and manage your weight entries.")
                .font(DSTypography.listTitle)
                .foregroundColor(Theme.ColorToken.textSecondaryOnDark)

            WeightHistoryListView(
                weightManager: viewModel.weightManager,
                measurementObserver: viewModel.measurementObserver
            )
            .accessibilityLabel("Weight entry history list")
            .accessibilityHint("Swipe through to review or delete individual entries")
        }
    }
}
