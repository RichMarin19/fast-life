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

                VStack(alignment: .leading, spacing: 6) {
                    Text("progress_story_did_you_know_title")
                        .font(DSTypography.listTitle)
                        .foregroundColor(Theme.ColorToken.textPrimary)

                    Text(text)
                        .font(DSTypography.cardBody)
                        .foregroundColor(Theme.ColorToken.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()
            }
        }
    }
}

// MARK: - Legacy TrendCard (Keep for backward compatibility)
