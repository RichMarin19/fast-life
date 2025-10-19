import SwiftUI

// MARK: - Design System Typography

/// Centralized text styles for consistent typography across all components
/// Industry Pattern: Type Scale (Apple HIG, Material Design, Figma)
/// Reference: https://developer.apple.com/design/human-interface-guidelines/typography
///
/// SINGLE SOURCE OF TRUTH: All text styles defined here
/// Never hardcode font styles in components - always reference DSTypography
///
/// Usage:
/// ```
/// Text("Title").font(DSTypography.cardTitle)
/// Text("Body").font(DSTypography.cardBody)
/// ```
enum DSTypography {
    // MARK: - Card Typography

    /// Card title (header text)
    /// Size: 16pt, Weight: Semibold
    /// Used by: DSCardHeader title, card headers
    static let cardTitle: Font = .system(size: 16, weight: .semibold)

    /// Card subtitle
    /// Size: 14pt, Weight: Regular
    /// Used by: Card subtitles, secondary headers
    static let cardSubtitle: Font = .system(size: 14, weight: .regular)

    /// Card body text
    /// Size: 15pt, Weight: Regular
    /// Used by: Main content text, descriptions
    static let cardBody: Font = .system(size: 15, weight: .regular)

    /// Card caption text
    /// Size: 13pt, Weight: Regular
    /// Used by: Labels, metadata, timestamps
    static let cardCaption: Font = .system(size: 13, weight: .regular)

    // MARK: - Display Typography (Large Values)

    /// Extra large display (hero numbers)
    /// Size: 48pt, Weight: Bold
    /// Used by: Current weight value, main metric display
    static let displayXL: Font = .system(size: 48, weight: .bold)

    /// Large display
    /// Size: 36pt, Weight: Bold
    /// Used by: Secondary large numbers
    static let displayL: Font = .system(size: 36, weight: .bold)

    /// Medium display
    /// Size: 24pt, Weight: Semibold
    /// Used by: Section headers, milestone numbers
    static let displayM: Font = .system(size: 24, weight: .semibold)

    /// Small display
    /// Size: 20pt, Weight: Semibold
    /// Used by: Subheaders, emphasized values
    static let displayS: Font = .system(size: 20, weight: .semibold)

    // MARK: - Stat Typography (Stats Cards)

    /// Stat value (large)
    /// Size: 32pt, Weight: Bold
    /// Used by: Main stat values
    static let statValueLarge: Font = .system(size: 32, weight: .bold)

    /// Stat value (medium)
    /// Size: 24pt, Weight: Semibold
    /// Used by: Secondary stat values
    static let statValueMedium: Font = .system(size: 24, weight: .semibold)

    /// Stat value (small)
    /// Size: 18pt, Weight: Semibold
    /// Used by: Tertiary stat values
    static let statValueSmall: Font = .system(size: 18, weight: .semibold)

    /// Stat label
    /// Size: 12pt, Weight: Medium
    /// Used by: Stat descriptions, labels
    static let statLabel: Font = .system(size: 12, weight: .medium)

    // MARK: - Button Typography

    /// Primary button text
    /// Size: 16pt, Weight: Semibold
    /// Used by: CTA buttons, primary actions
    static let buttonPrimary: Font = .system(size: 16, weight: .semibold)

    /// Secondary button text
    /// Size: 15pt, Weight: Medium
    /// Used by: Secondary actions, links
    static let buttonSecondary: Font = .system(size: 15, weight: .medium)

    // MARK: - List Typography

    /// List item title
    /// Size: 16pt, Weight: Medium
    /// Used by: History list items, settings rows
    static let listTitle: Font = .system(size: 16, weight: .medium)

    /// List item subtitle
    /// Size: 14pt, Weight: Regular
    /// Used by: List item secondary text
    static let listSubtitle: Font = .system(size: 14, weight: .regular)

    /// List item caption
    /// Size: 12pt, Weight: Regular
    /// Used by: Timestamps, metadata in lists
    static let listCaption: Font = .system(size: 12, weight: .regular)

    // MARK: - Helper Methods

    /// Get monospacedDigit variant for numbers (prevents width jumping)
    /// Used by: Weight values, timers, any changing numbers
    static func monospacedDigit(_ font: Font) -> Font {
        return font.monospacedDigit()
    }
}

// MARK: - Text Style Modifiers

extension Text {
    /// Apply card title style
    func cardTitleStyle() -> Text {
        self.font(DSTypography.cardTitle)
            .foregroundColor(DSColors.textPrimary)
    }

    /// Apply card body style
    func cardBodyStyle() -> Text {
        self.font(DSTypography.cardBody)
            .foregroundColor(DSColors.textPrimary)
    }

    /// Apply card caption style
    func cardCaptionStyle() -> Text {
        self.font(DSTypography.cardCaption)
            .foregroundColor(DSColors.textSecondary)
    }

    /// Apply stat value style (with monospaced digits)
    func statValueStyle() -> Text {
        self.font(DSTypography.monospacedDigit(DSTypography.statValueLarge))
            .foregroundColor(DSColors.textPrimary)
    }

    /// Apply stat label style
    func statLabelStyle() -> Text {
        self.font(DSTypography.statLabel)
            .foregroundColor(DSColors.textSecondary)
    }
}
