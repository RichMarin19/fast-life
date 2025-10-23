import SwiftUI

// MARK: - DSCoachBar (v1.3 - Universal Standardization)

/// DSCoachBar - Reusable motivational header bar component
/// Per Universal Standardization Architecture (Phase v1.3):
///   - Level 3: Reusable Component (used across all 5 trackers)
///   - Industry Pattern: Apple Health motivational headers
///   - Extracted from CoachBar (WeightComponents.swift lines 1036-1084)
///
/// **Usage Locations:**
///   - Weight Tracker: "Your LIFe Journey" behavioral anchor
///   - Future: Fasting, Hydration, Sleep, Mood trackers
///
/// **Design Tokens:**
///   - Uses DSSpacing.cardPadding (16pt) for uniform container sizing
///   - Uses Theme.ColorToken for all colors
///   - Follows Apple HIG for accessibility (44×44pt tap targets)
///
/// **Code Savings:**
///   - Eliminates ~48 lines of duplicated code per tracker
///   - Future savings: ~240 lines across 5 trackers
///
/// **Industry Standard:**
///   - Apple Health motivational header pattern
///   - White text on accent background for high contrast
///   - SF Symbol icon + rounded typography for emotional warmth
struct DSCoachBar: View {
    // MARK: - Parameters

    /// Motivational message text
    let text: String

    /// SF Symbol icon name (default: "sparkles")
    let icon: String

    /// Background color (default: Theme.ColorToken.accentInfo)
    let backgroundColor: Color

    /// Hide callback (optional - adds eye.slash button if provided)
    let onHide: (() -> Void)?

    // MARK: - Initialization

    /// Create a coach bar with full customization
    /// - Parameters:
    ///   - text: Motivational message text
    ///   - icon: SF Symbol name (default: "sparkles")
    ///   - backgroundColor: Accent color (default: Theme.ColorToken.accentInfo)
    ///   - onHide: Optional hide callback (adds eye.slash button if provided)
    init(
        text: String,
        icon: String = "sparkles",
        backgroundColor: Color = Theme.ColorToken.accentInfo,
        onHide: (() -> Void)? = nil
    ) {
        self.text = text
        self.icon = icon
        self.backgroundColor = backgroundColor
        self.onHide = onHide
    }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Background layer
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(backgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(backgroundColor.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: Theme.ColorToken.shadowCard, radius: 8, x: 0, y: 4)

            // Content layer
            VStack {
                Spacer(minLength: 0)  // Top spacer - flexible

                HStack(spacing: 8) {
                    // Icon: SF Symbol, 18-20pt, WHITE
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)

                    Text(text)
                        .font(.system(size: 21, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)  // WHITE for high contrast
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer()
                }
                .padding(.leading, DSSpacing.cardPadding)  // 16pt horizontal - FIXED
                .padding(.trailing, DSSpacing.cardPadding + 44)  // Extra space for eye.slash button
                .frame(maxWidth: .infinity, alignment: .leading)

                Spacer(minLength: 0)  // Bottom spacer - flexible
            }

            // Eye.slash button overlaid in top-right corner (if onHide provided)
            if let hideAction = onHide {
                Button(action: hideAction) {
                    Image(systemName: "eye.slash")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.9))
                        .frame(width: 44, height: 44)  // Apple HIG tap target
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Hide coach bar")
            }
        }
        .frame(height: 66)  // 🔧 FIX #18: LOCK THE ENTIRE CONTAINER HEIGHT at 66pt
        .clipped()  // 🔧 FIX #19: Clip shadow overflow to prevent visual size increase beyond fixed height
        .accessibilityLabel("Coach tip: \(text)")
    }
}

// MARK: - Convenience Initializers

extension DSCoachBar {
    /// Create a coach bar with default accent color (Theme.ColorToken.accentInfo)
    /// - Parameters:
    ///   - text: Motivational message text
    ///   - icon: SF Symbol name (default: "sparkles")
    ///   - onHide: Optional hide callback
    init(
        text: String,
        icon: String = "sparkles",
        onHide: (() -> Void)? = nil
    ) {
        self.init(
            text: text,
            icon: icon,
            backgroundColor: Theme.ColorToken.accentInfo,
            onHide: onHide
        )
    }
}

// MARK: - Preview

#Preview("DSCoachBar - Various Styles") {
    ZStack {
        // Dark background like Weight Tracker
        Color(red: 10/255, green: 18/255, blue: 36/255)
            .ignoresSafeArea()

        VStack(spacing: 20) {
            // Default accent color (accentInfo)
            DSCoachBar(
                text: "Progress in motion — your consistency shows!",
                onHide: {
                    Log.debug("Hide coach bar", category: .general)
                }
            )

            // Custom color (accentPrimary)
            DSCoachBar(
                text: "Balance is mastery in motion — keep showing up!",
                icon: "heart.text.square",
                backgroundColor: Theme.ColorToken.accentPrimary,
                onHide: {
                    Log.debug("Hide coach bar", category: .general)
                }
            )

            // Custom color (accentGold)
            DSCoachBar(
                text: "Weight gain is feedback, not failure — hydrate and sleep strong!",
                icon: "leaf.fill",
                backgroundColor: Theme.ColorToken.accentGold,
                onHide: {
                    Log.debug("Hide coach bar", category: .general)
                }
            )

            // No hide button
            DSCoachBar(
                text: "Small wins compound. Keep stacking the days!",
                icon: "flame.fill",
                backgroundColor: Theme.ColorToken.stateSuccess
            )
        }
        .padding(.horizontal, 16)
    }
}
