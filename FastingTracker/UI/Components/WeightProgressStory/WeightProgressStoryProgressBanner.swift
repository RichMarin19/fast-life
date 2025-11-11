import SwiftUI

struct ProgressBanner: View {
    let text: String
    let accent: Color
    let onHide: () -> Void  // Hide callback

    private var accessibilityLabelText: String {
        let template = NSLocalizedString(
            "progress_story_banner_accessibility",
            comment: "Accessibility label announcing progress banner text"
        )
        return String(format: template, text)
    }

    var body: some View {
        DSBanner(ice: onHide) {
            HStack(spacing: DSSpacing.cardElementSpacing) {
                Image(systemName: "square.stack.3d.up.fill")  // 🔧 FIX #3: Unique icon representing small wins compounding/stacking
                    .font(DSTypography.listTitle)
                    .foregroundColor(accent)

                Text(text)
                    .font(DSTypography.statValueSmall)
                    .foregroundColor(Theme.ColorToken.textPrimary.opacity(0.9))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityLabel(accessibilityLabelText)
    }
}

/// Circular Trend Ring Card - "Your LIFe Journey" luxury visual card
/// Per FastLIFe_Your_LIFe_Journey_UIUX_v1.0.md §2
/// Circular progress ring with gradient based on trend state
/// Industry Pattern: Apple Watch Activity Rings
