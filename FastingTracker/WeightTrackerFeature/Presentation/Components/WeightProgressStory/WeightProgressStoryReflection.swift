import SwiftUI

struct ReflectionNudge: View {
    let text: String        // Pre-computed reflection prompt (prevents random changes during drag)
    let onHide: () -> Void  // Hide callback
    let onTap: () -> Void   // Tap callback (stub for now)

    private var accessibilityLabelText: String {
        NSLocalizedString(
            "progress_story_reflection_accessibility_label",
            comment: "Accessibility label for reflection prompt banner"
        )
    }

    private var accessibilityHintText: String {
        let template = NSLocalizedString(
            "progress_story_reflection_accessibility_hint",
            comment: "Accessibility hint describing how to respond to reflection prompt"
        )
        return String(format: template, text)
    }

    var body: some View {
        DSBanner(ice: onHide) {
            HStack(spacing: DSSpacing.cardElementSpacing) {
                Image(systemName: "sparkle")
                    .foregroundColor(Theme.ColorToken.accentGold)
                    .font(DSTypography.listTitle)

                Text(text)
                    .font(DSTypography.statValueSmall)
                    .foregroundColor(Theme.ColorToken.textPrimary)
                    .italic()
                    .lineLimit(2)  // Enforce 2-line max for consistent height
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .onTapGesture {
            onTap()
        }
        .accessibilityLabel(accessibilityLabelText)
        .accessibilityHint(accessibilityHintText)
    }
}

/// Did You Know Banner - Optional educational micro-tip
/// Per Stacked v1.2 spec: Mint surface with eye.slash dismiss on RIGHT (matching DSCard pattern)
/// Updated: Eye-slash moved from LEFT to RIGHT to match DSCardHeader
/// v1.2e: Refactored to use DSBanner component for uniform container sizing
///
/// **STANDARD CARD TEXT SIZE:** DSTypography.statValueSmall (18pt semibold rounded)
/// This is the standard text size for all banner cards in Progress Story unless explicitly specified otherwise.
/// Ensures visual consistency across ProgressBanner, ReflectionNudge, RecapRow, and DidYouKnowBanner.
