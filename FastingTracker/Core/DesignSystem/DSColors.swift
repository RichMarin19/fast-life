import SwiftUI

// MARK: - Design System Colors

/// ⚠️ DEPRECATED: Use Theme.ColorToken directly instead
///
/// This wrapper enum is being phased out in favor of Theme.ColorToken.
/// All DSColors properties are simple aliases to Theme.ColorToken.
///
/// Migration Guide:
/// - DSColors.cardBackground → Theme.ColorToken.card
/// - DSColors.cardShadow → Theme.ColorToken.shadowCard
/// - DSColors.textPrimary → Theme.ColorToken.textPrimary
/// - DSColors.textSecondary → Theme.ColorToken.textSecondary
/// - DSColors.accentPrimary → Theme.ColorToken.accentPrimary
/// - DSColors.accentSuccess → Theme.ColorToken.stateSuccess
/// - DSColors.accentWarning → Theme.ColorToken.stateWarning
/// - DSColors.accentError → Theme.ColorToken.stateError
/// - DSColors.chartLine → Theme.ColorToken.accentPrimary
/// - DSColors.chartGoalLine → Theme.ColorToken.stateSuccess
/// - DSColors.screenBackground → Theme.ColorToken.bgDeepStart
///
/// Reason for deprecation: Single source of truth
/// Industry Pattern: Design token consolidation (Apple HIG, Material Design)
/// Timeline: Will be removed after all references are migrated
@available(*, deprecated, message: "Use Theme.ColorToken directly instead. See migration guide in comments.")
enum DSColors {
    // MARK: - Card Colors

    /// Card background color (white)
    /// Used by: All card containers
    static let cardBackground: Color = Theme.ColorToken.card

    /// Card shadow color (black with opacity)
    /// Used by: All card shadows
    static let cardShadow: Color = Theme.ColorToken.shadowCard

    // MARK: - Text Colors

    /// Primary text color (high contrast)
    /// Used by: Headers, important values, main content
    static let textPrimary: Color = Theme.ColorToken.textPrimary

    /// Secondary text color (medium contrast)
    /// Used by: Labels, descriptions, supporting text
    static let textSecondary: Color = Theme.ColorToken.textSecondary

    /// Tertiary text color (low contrast)
    /// Used by: Placeholders, disabled text
    static let textTertiary: Color = .secondary

    // MARK: - Accent Colors

    /// Primary accent color (brand color)
    /// Used by: CTA buttons, primary actions, highlights
    static let accentPrimary: Color = Theme.ColorToken.accentPrimary

    /// Success color (green)
    /// Used by: Positive progress, achievements, success states
    static let accentSuccess: Color = Theme.ColorToken.accentSuccess

    /// Warning color (orange/yellow)
    /// Used by: Warnings, alerts, attention needed
    static let accentWarning: Color = Theme.ColorToken.accentWarning

    /// Error color (red)
    /// Used by: Errors, destructive actions, critical alerts
    static let accentError: Color = Theme.ColorToken.accentError

    // MARK: - Interactive Colors

    /// Control background (buttons, tappable areas)
    /// Used by: Buttons, interactive elements
    static let controlBackground: Color = Theme.ColorToken.accentPrimary

    /// Control text color (white for dark backgrounds)
    /// Used by: Text on colored buttons
    static let controlText: Color = .white

    /// Disabled control color
    /// Used by: Disabled buttons, inactive states
    static let controlDisabled: Color = .gray.opacity(0.3)

    // MARK: - Background Colors

    /// Screen background (luxury gradient handled separately)
    /// Used by: TrackerScreenShell backgrounds
    /// Note: Gradients still use existing GradientStyle system
    static let screenBackground: Color = Color(red: 10/255, green: 18/255, blue: 36/255)

    /// Overlay background (for sheets, modals)
    /// Used by: Popover backgrounds, sheet backgrounds
    static let overlayBackground: Color = .white

    // MARK: - Divider Colors

    /// Divider line color
    /// Used by: Section dividers, separators
    static let divider: Color = .gray.opacity(0.2)

    // MARK: - Chart Colors

    /// Chart line color (primary data)
    /// Used by: Weight trend line, main chart data
    static let chartLine: Color = Theme.ColorToken.accentPrimary

    /// Chart goal line color
    /// Used by: Goal reference line on charts
    static let chartGoalLine: Color = Theme.ColorToken.accentSuccess

    /// Chart fill gradient start
    /// Used by: Area chart fills
    static let chartFillStart: Color = Theme.ColorToken.accentPrimary.opacity(0.3)

    /// Chart fill gradient end
    /// Used by: Area chart fills
    static let chartFillEnd: Color = Theme.ColorToken.accentPrimary.opacity(0.05)
}

// MARK: - Color Extension - Hex Support

/// Extension to initialize Color from hex strings
/// Industry Pattern: Figma/Sketch/Design handoff workflows
/// Reference: Common iOS pattern for design system integration
extension Color {
    /// Initialize Color from hex string (e.g., "#22D1A3" or "22D1A3")
    /// - Parameter hex: Hex color string with or without "#" prefix
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
