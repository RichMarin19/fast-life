import SwiftUI

// MARK: - Design System Colors

/// Centralized color tokens for consistent theming across all components
/// Industry Pattern: Design Tokens (Apple HIG, Material Design, Figma)
/// Reference: https://developer.apple.com/design/human-interface-guidelines/color
///
/// SINGLE SOURCE OF TRUTH: All color values defined here
/// Never hardcode colors in components - always reference DSColors
///
/// BACKWARDS COMPATIBILITY: Uses existing Theme.ColorToken values
/// This ensures consistency with current luxury gradient system
///
/// Usage:
/// ```
/// .foregroundColor(DSColors.textPrimary)
/// .background(DSColors.cardBackground)
/// ```
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

    /// Success color (green) - Maps to stateSuccess
    /// Used by: Positive progress, achievements, success states
    static let accentSuccess: Color = Theme.ColorToken.stateSuccess

    /// Warning color (orange/yellow) - Maps to stateWarning
    /// Used by: Warnings, alerts, attention needed
    static let accentWarning: Color = Theme.ColorToken.stateWarning

    /// Error color (red) - Maps to stateError
    /// Used by: Errors, destructive actions, critical alerts
    static let accentError: Color = Theme.ColorToken.stateError

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
    static let chartGoalLine: Color = Theme.ColorToken.stateSuccess

    /// Chart fill gradient start
    /// Used by: Area chart fills
    static let chartFillStart: Color = Theme.ColorToken.accentPrimary.opacity(0.3)

    /// Chart fill gradient end
    /// Used by: Area chart fills
    static let chartFillEnd: Color = Theme.ColorToken.accentPrimary.opacity(0.05)
}
