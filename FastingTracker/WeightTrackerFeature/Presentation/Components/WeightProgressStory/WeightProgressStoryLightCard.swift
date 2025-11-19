import SwiftUI

// MARK: - Progress Story Surface Styles

/// Surface palettes for Progress Story light cards.
/// Provides a single source of truth for background, stroke, and shadow tokens.
enum WeightProgressStorySurfaceStyle {
    case ice
    case ivory
    case mint
    case custom(Color)

    var background: Color {
        switch self {
        case .ice: return Theme.ColorToken.surfaceIce
        case .ivory: return Theme.ColorToken.surfaceIvory
        case .mint: return Theme.ColorToken.surfaceMint
        case let .custom(color): return color
        }
    }

    var stroke: Color {
        Theme.ColorToken.strokeLight
    }

    var shadow: Color {
        Theme.ColorToken.shadowCard
    }
}

// MARK: - Progress Story Surface Card

/// Shared light-surface card used across Progress Story components.
/// Wraps content with standardized padding, hide affordance, and tokens.
struct WeightProgressStorySurfaceCard<Content: View>: View {
    let style: WeightProgressStorySurfaceStyle
    let content: Content
    let onHide: () -> Void

    init(style: WeightProgressStorySurfaceStyle,
         onHide: @escaping () -> Void,
         @ViewBuilder content: () -> Content) {
        self.style = style
        self.onHide = onHide
        self.content = content()
    }

    var body: some View {
        content
            .padding(DSSpacing.cardPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(alignment: .topTrailing) {
                let hideCardLabel = NSLocalizedString(
                    "progress_story_hide_card_accessibility",
                    comment: "Accessibility label for button that hides a Progress Story card"
                )
                Button(action: onHide) {
                    Image(systemName: "eye.slash")
                        .font(DSTypography.iconButton)
                        .foregroundColor(Theme.ColorToken.textSecondary)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(hideCardLabel)
            }
            .background(
                RoundedRectangle(cornerRadius: DSCornerRadius.card, style: .continuous)
                    .fill(style.background)
                    .overlay(
                        RoundedRectangle(cornerRadius: DSCornerRadius.card, style: .continuous)
                            .stroke(style.stroke, lineWidth: 1)
                    )
                    .shadow(color: style.shadow, radius: 10, x: 0, y: 6)
            )
    }
}

@available(*, deprecated, renamed: "WeightProgressStorySurfaceCard")
typealias LightCard<Content: View> = WeightProgressStorySurfaceCard<Content>
