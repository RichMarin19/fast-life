import SwiftUI

struct DidYouKnowBanner: View {
    let text: String
    let onHide: () -> Void  // Hide callback

    var body: some View {
        DSBanner(ice: onHide) {
            HStack(spacing: DSSpacing.cardElementSpacing) {
                Image(systemName: "lightbulb")
                    .foregroundColor(Theme.ColorToken.accentInfo)
                    .font(DSTypography.listTitle)

                Text(text)
                    .font(DSTypography.statValueSmall)
                    .foregroundColor(Theme.ColorToken.textPrimary)

                Spacer()
            }
        }
    }
}

// MARK: - Legacy TrendCard (Keep for backward compatibility)
