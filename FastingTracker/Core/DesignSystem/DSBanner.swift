import SwiftUI

// MARK: - DSBanner (v1.2e - Universal Standardization)

/// DSBanner - Reusable banner/card component with consistent container sizing
/// Per Universal Standardization Architecture (Phase v1.2e):
///   - Level 3: Reusable Component (used in multiple custom contents)
///   - Industry Pattern: iOS card containers (Apple Health, Settings, App Store)
///   - Extracted from ProgressBanner + ReflectionNudge + RecapRow + DidYouKnowBanner
///
/// **Usage Locations:**
///   - ProgressBanner (WeightComponents.swift) - Motivational messages
///   - ReflectionNudge (WeightComponents.swift) - Behavioral prompts
///   - RecapRow (WeightComponents.swift) - Summary statistics
///   - DidYouKnowBanner (WeightComponents.swift) - Educational tips
///   - Future: Fasting/Hydration/Sleep/Mood tracker banners
///
/// **Design Tokens:**
///   - Uses DSSpacing.cardPadding (16pt) for uniform container sizing
///   - Uses Theme.ColorToken for all colors
///   - Follows Apple HIG for card/container design
///
/// **Code Savings:**
///   - Eliminates ~90-120 lines of duplicated code
///   - Single source of truth for banner container styling
///
/// **Industry Standard:**
///   - 16pt padding = iOS standard (Apple HIG, 8pt grid system)
///   - Consistent vertical sizing across all banner types
///   - Used by: Apple Health, Apple Music, App Store, Settings
struct DSBanner<Content: View>: View {
    // MARK: - Parameters

    /// Background surface color
    let surface: Color

    /// Corner radius in points (default: 14pt per Apple HIG)
    let cornerRadius: CGFloat

    /// Enable shadow (default: true)
    let enableShadow: Bool

    /// Shadow color
    let shadowColor: Color

    /// Shadow radius
    let shadowRadius: CGFloat

    /// Shadow offset
    let shadowOffset: (x: CGFloat, y: CGFloat)

    /// Enable stroke border (default: true)
    let enableStroke: Bool

    /// Stroke color
    let strokeColor: Color

    /// Stroke width
    let strokeWidth: CGFloat

    /// Hide callback (optional)
    let onHide: (() -> Void)?

    /// Fixed height for banner container (optional - if nil, uses natural height)
    let fixedHeight: CGFloat?

    /// Banner content
    let content: Content

    // MARK: - Initialization

    /// Create a banner with full customization
    /// - Parameters:
    ///   - surface: Background color (default: white)
    ///   - cornerRadius: Corner radius in points (default: 14)
    ///   - enableShadow: Enable shadow effect (default: true)
    ///   - shadowColor: Shadow color (default: Theme.ColorToken.shadowCard)
    ///   - shadowRadius: Shadow blur radius (default: 8)
    ///   - shadowOffset: Shadow offset x,y (default: 0, 4)
    ///   - enableStroke: Enable border stroke (default: true)
    ///   - strokeColor: Border color (default: Theme.ColorToken.strokeLight)
    ///   - strokeWidth: Border width (default: 1)
    ///   - onHide: Optional hide callback (adds eye.slash button if provided)
    ///   - fixedHeight: Optional fixed height for container (nil = natural height)
    ///   - content: Banner content view
    init(
        surface: Color = .white,
        cornerRadius: CGFloat = 14,
        enableShadow: Bool = true,
        shadowColor: Color = Theme.ColorToken.shadowCard,
        shadowRadius: CGFloat = 8,
        shadowOffset: (x: CGFloat, y: CGFloat) = (0, 4),
        enableStroke: Bool = true,
        strokeColor: Color = Theme.ColorToken.strokeLight,
        strokeWidth: CGFloat = 1,
        onHide: (() -> Void)? = nil,
        fixedHeight: CGFloat? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.surface = surface
        self.cornerRadius = cornerRadius
        self.enableShadow = enableShadow
        self.shadowColor = shadowColor
        self.shadowRadius = shadowRadius
        self.shadowOffset = shadowOffset
        self.enableStroke = enableStroke
        self.strokeColor = strokeColor
        self.strokeWidth = strokeWidth
        self.onHide = onHide
        self.fixedHeight = fixedHeight
        self.content = content()
    }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Background layer
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(surface)
                .overlay(
                    enableStroke ?
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(strokeColor, lineWidth: strokeWidth)
                        : nil
                )
                .shadow(
                    color: enableShadow ? shadowColor : .clear,
                    radius: shadowRadius,
                    x: shadowOffset.x,
                    y: shadowOffset.y
                )

            // Content layer
            VStack {
                Spacer(minLength: 0)  // Top spacer - flexible

                content
                    .padding(.horizontal, DSSpacing.cardPadding)  // 16pt horizontal - FIXED
                    .frame(maxWidth: .infinity, alignment: .leading)

                Spacer(minLength: 0)  // Bottom spacer - flexible
            }

            // Eye.slash button (if onHide provided)
            if let hideAction = onHide {
                Button(action: hideAction) {
                    Image(systemName: "eye.slash")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Theme.ColorToken.textSecondary)
                        .frame(width: 44, height: 44)  // Apple HIG tap target
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Hide banner")
            }
        }
        .frame(height: fixedHeight)  // 🔧 FIX #18: LOCK THE ENTIRE CONTAINER HEIGHT at 66pt
        .clipped()  // 🔧 FIX #19: Clip shadow overflow to prevent visual size increase beyond fixed height
    }
}

// MARK: - Convenience Initializers

extension DSBanner {
    /// Create a white banner (for progress/motivational messages)
    /// - Parameters:
    ///   - onHide: Optional hide callback
    ///   - content: Banner content view
    init(
        white onHide: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.init(
            surface: Theme.ColorToken.surfaceIce,  // Universal Ice standard (Phase v1.3e)
            cornerRadius: 14,
            enableShadow: true,
            shadowColor: Theme.ColorToken.shadowCard,
            shadowRadius: 8,
            shadowOffset: (0, 4),
            enableStroke: true,
            strokeColor: Theme.ColorToken.strokeLight,
            strokeWidth: 1,
            onHide: onHide,
            fixedHeight: 66,  // 🔧 FIX #15: Match CoachBar height (14pt padding + ~38pt content + 14pt padding)
            content: content
        )
    }

    /// Create a mint banner (for educational tips, recap rows)
    /// - Parameters:
    ///   - onHide: Optional hide callback
    ///   - content: Banner content view
    init(
        mint onHide: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.init(
            surface: Theme.ColorToken.surfaceIce,  // Universal Ice standard (Phase v1.3e)
            cornerRadius: 14,
            enableShadow: false,  // Mint banners typically don't have shadow
            shadowColor: .clear,
            shadowRadius: 0,
            shadowOffset: (0, 0),
            enableStroke: true,
            strokeColor: Theme.ColorToken.strokeLight,
            strokeWidth: 1,
            onHide: onHide,
            fixedHeight: 66,  // 🔧 FIX #15: Match CoachBar height
            content: content
        )
    }

    /// Create an ice banner (for reflection nudges)
    /// - Parameters:
    ///   - onHide: Optional hide callback
    ///   - content: Banner content view
    init(
        ice onHide: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.init(
            surface: Theme.ColorToken.surfaceIce,
            cornerRadius: 14,
            enableShadow: true,
            shadowColor: Theme.ColorToken.shadowCard,
            shadowRadius: 6,
            shadowOffset: (0, 3),
            enableStroke: true,
            strokeColor: Theme.ColorToken.strokeLight,
            strokeWidth: 1,
            onHide: onHide,
            fixedHeight: 66,  // 🔧 FIX #15: Match CoachBar height
            content: content
        )
    }
}

// MARK: - Preview

#Preview("DSBanner - Various Styles") {
    ZStack {
        // Dark background like Weight Tracker
        Color(red: 10/255, green: 18/255, blue: 36/255)
            .ignoresSafeArea()

        VStack(spacing: 20) {
            // White banner (motivational)
            DSBanner(white: {
                Log.debug("Hide white banner", category: .general)
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .foregroundColor(Theme.ColorToken.accentPrimary)
                        .font(.system(size: 20))

                    Text("Small wins compound. Keep stacking the days!")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(Theme.ColorToken.textPrimary)

                    Spacer(minLength: 0)
                }
            }

            // Mint banner (educational)
            DSBanner(mint: {
                Log.debug("Hide mint banner", category: .general)
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "lightbulb")
                        .foregroundColor(Theme.ColorToken.accentInfo)
                        .font(.system(size: 16))

                    Text("Drinking water before meals can reduce calorie intake.")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(Theme.ColorToken.textPrimary)

                    Spacer(minLength: 0)
                }
            }

            // Ice banner (reflection)
            DSBanner(ice: {
                Log.debug("Hide ice banner", category: .general)
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "sparkle")
                        .foregroundColor(Theme.ColorToken.accentGold)
                        .font(.system(size: 16))

                    Text("One small habit to try this week?")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Theme.ColorToken.textPrimary)
                        .italic()

                    Spacer(minLength: 0)

                    Image(systemName: "chevron.right")
                        .foregroundColor(Theme.ColorToken.textSecondary.opacity(0.6))
                        .font(.system(size: 12))
                }
            }

            // Custom banner (no hide button)
            DSBanner(
                surface: Theme.ColorToken.accentInfo,
                cornerRadius: 14,
                enableShadow: true,
                shadowColor: Theme.ColorToken.shadowCard,
                shadowRadius: 8,
                shadowOffset: (0, 4),
                enableStroke: false,
                strokeColor: .clear,
                strokeWidth: 0,
                onHide: nil
            ) {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .foregroundColor(.white)
                        .font(.system(size: 18))

                    Text("Progress in motion — your consistency shows!")
                        .font(.system(size: 21, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)

                    Spacer(minLength: 0)
                }
            }
        }
        .padding(.horizontal, 16)
    }
}
