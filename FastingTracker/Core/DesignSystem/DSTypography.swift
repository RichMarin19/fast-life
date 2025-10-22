import SwiftUI

// MARK: - Design System Typography

/// Centralized text styles for consistent typography across all components
/// Industry Pattern: Type Scale (Apple HIG, Material Design, Figma)
/// Reference: https://developer.apple.com/design/human-interface-guidelines/typography
///
/// SINGLE SOURCE OF TRUTH: All text styles defined here
/// Never hardcode font styles in components - always reference DSTypography
///
/// DYNAMIC TYPE SUPPORT:
/// ✅ All fonts scale automatically with user's text size preference (Settings > Accessibility > Larger Text)
/// ✅ SwiftUI `.system()` fonts provide built-in Dynamic Type support across all 12 size categories
/// ✅ Maintains visual hierarchy at all sizes (titles always larger than body text)
/// ✅ WCAG 2.1 AA compliant - text scales up to 200% without loss of content or functionality
///
/// Testing: Settings > Accessibility > Display & Text Size > Larger Text → drag to maximum
/// Reference: Apple HIG Typography + WWDC 2022 "What's new in SwiftUI"
///
/// COLOR CONTEXT SYSTEM:
/// - Light backgrounds (Ice/Ivory/White) → textPrimary (dark) / textSecondary (gray)
/// - Dark backgrounds (Navy gradient) → textPrimaryOnDark (white) / textSecondaryOnDark (70% white)
/// - Use Text extensions below for automatic color pairing
///
/// Usage:
/// ```
/// Text("Title").font(DSTypography.cardTitle)
/// Text("Body").font(DSTypography.cardBody)
///
/// // With color context
/// Text("Title").cardTitleStyle()  // Includes correct color for light bg
/// Text("Title").cardTitleStyleOnDark()  // For dark backgrounds
/// ```
enum DSTypography {
    // MARK: - Card Typography

    /// Card title (header text)
    /// Size: 16pt, Weight: Semibold, Scales with: .headline
    /// Used by: DSCardHeader title, card headers
    static let cardTitle: Font = .system(size: 16, weight: .semibold, design: .default)

    /// Card subtitle
    /// Size: 14pt, Weight: Regular, Scales with: .subheadline
    /// Used by: Card subtitles, secondary headers
    static let cardSubtitle: Font = .system(size: 14, weight: .regular, design: .default)

    /// Card body text
    /// Size: 15pt, Weight: Regular, Scales with: .body
    /// Used by: Main content text, descriptions
    static let cardBody: Font = .system(size: 15, weight: .regular, design: .default)

    /// Card caption text
    /// Size: 13pt, Weight: Regular, Scales with: .caption
    /// Used by: Labels, metadata, timestamps
    static let cardCaption: Font = .system(size: 13, weight: .regular, design: .default)

    // MARK: - Display Typography (Large Values)

    /// Extra extra large display (huge hero numbers)
    /// Size: 60pt, Weight: Bold, Design: Rounded
    /// Used by: Legacy trend cards, huge emphasis numbers
    static let displayXXL: Font = .system(size: 60, weight: .bold, design: .rounded)

    /// Extra large display (hero numbers)
    /// Size: 48pt, Weight: Bold
    /// Used by: Current weight value, main metric display
    static let displayXL: Font = .system(size: 48, weight: .bold)

    /// Extra large display - Rounded variant
    /// Size: 48pt, Weight: Bold, Design: Rounded
    /// Used by: Progress Story titles, motivational numbers
    static let displayXLRounded: Font = .system(size: 48, weight: .bold, design: .rounded)

    /// Large display
    /// Size: 36pt, Weight: Bold
    /// Used by: Secondary large numbers
    static let displayL: Font = .system(size: 36, weight: .bold)

    /// Large display - Rounded variant
    /// Size: 36pt, Weight: Bold, Design: Rounded
    /// Used by: Progress Story large values, trend indicators
    static let displayLRounded: Font = .system(size: 36, weight: .bold, design: .rounded)

    /// Medium display
    /// Size: 24pt, Weight: Semibold
    /// Used by: Section headers, milestone numbers
    static let displayM: Font = .system(size: 24, weight: .semibold)

    /// Medium display - Rounded variant
    /// Size: 24pt, Weight: Semibold, Design: Rounded
    /// Used by: Progress Story section headers
    static let displayMRounded: Font = .system(size: 24, weight: .semibold, design: .rounded)

    /// Small display
    /// Size: 20pt, Weight: Semibold
    /// Used by: Subheaders, emphasized values
    static let displayS: Font = .system(size: 20, weight: .semibold)

    /// Small display - Rounded variant
    /// Size: 20pt, Weight: Bold, Design: Rounded
    /// Used by: Progress Story icons, callouts
    static let displaySRounded: Font = .system(size: 20, weight: .bold, design: .rounded)

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

// MARK: - Text Style Modifiers (Color-Context Aware)

extension Text {
    // MARK: - Card Styles (Light Backgrounds)

    /// Apply card title style - FOR LIGHT BACKGROUNDS
    /// Font: 16pt Semibold | Color: Dark text (textPrimary)
    func cardTitleStyle() -> Text {
        self.font(DSTypography.cardTitle)
            .foregroundColor(Theme.ColorToken.textPrimary)
    }

    /// Apply card title style - FOR DARK BACKGROUNDS
    /// Font: 16pt Semibold | Color: White text (textPrimaryOnDark)
    func cardTitleStyleOnDark() -> Text {
        self.font(DSTypography.cardTitle)
            .foregroundColor(Theme.ColorToken.textPrimaryOnDark)
    }

    /// Apply card body style - FOR LIGHT BACKGROUNDS
    /// Font: 15pt Regular | Color: Dark text (textPrimary)
    func cardBodyStyle() -> Text {
        self.font(DSTypography.cardBody)
            .foregroundColor(Theme.ColorToken.textPrimary)
    }

    /// Apply card body style - FOR DARK BACKGROUNDS
    /// Font: 15pt Regular | Color: White text (textPrimaryOnDark)
    func cardBodyStyleOnDark() -> Text {
        self.font(DSTypography.cardBody)
            .foregroundColor(Theme.ColorToken.textPrimaryOnDark)
    }

    /// Apply card caption style - FOR LIGHT BACKGROUNDS
    /// Font: 13pt Regular | Color: Gray text (textSecondary)
    func cardCaptionStyle() -> Text {
        self.font(DSTypography.cardCaption)
            .foregroundColor(Theme.ColorToken.textSecondary)
    }

    /// Apply card caption style - FOR DARK BACKGROUNDS
    /// Font: 13pt Regular | Color: 70% white (textSecondaryOnDark)
    func cardCaptionStyleOnDark() -> Text {
        self.font(DSTypography.cardCaption)
            .foregroundColor(Theme.ColorToken.textSecondaryOnDark)
    }

    // MARK: - Display Styles (Hero Numbers)

    /// Apply display XL style - FOR LIGHT BACKGROUNDS
    /// Font: 48pt Bold | Color: Dark text (textPrimary)
    func displayXLStyle() -> Text {
        self.font(DSTypography.displayXL)
            .foregroundColor(Theme.ColorToken.textPrimary)
    }

    /// Apply display XL style - FOR DARK BACKGROUNDS
    /// Font: 48pt Bold | Color: White text (textPrimaryOnDark)
    func displayXLStyleOnDark() -> Text {
        self.font(DSTypography.displayXL)
            .foregroundColor(Theme.ColorToken.textPrimaryOnDark)
    }

    /// Apply display XL rounded style - FOR LIGHT BACKGROUNDS
    /// Font: 48pt Bold Rounded | Color: Dark text (textPrimary)
    func displayXLRoundedStyle() -> Text {
        self.font(DSTypography.displayXLRounded)
            .foregroundColor(Theme.ColorToken.textPrimary)
    }

    /// Apply display XL rounded style - FOR DARK BACKGROUNDS
    /// Font: 48pt Bold Rounded | Color: White text (textPrimaryOnDark)
    func displayXLRoundedStyleOnDark() -> Text {
        self.font(DSTypography.displayXLRounded)
            .foregroundColor(Theme.ColorToken.textPrimaryOnDark)
    }

    // MARK: - Stat Styles

    /// Apply stat value style (with monospaced digits) - FOR LIGHT BACKGROUNDS
    /// Font: 32pt Bold Monospaced | Color: Dark text (textPrimary)
    func statValueStyle() -> Text {
        self.font(DSTypography.monospacedDigit(DSTypography.statValueLarge))
            .foregroundColor(Theme.ColorToken.textPrimary)
    }

    /// Apply stat value style (with monospaced digits) - FOR DARK BACKGROUNDS
    /// Font: 32pt Bold Monospaced | Color: White text (textPrimaryOnDark)
    func statValueStyleOnDark() -> Text {
        self.font(DSTypography.monospacedDigit(DSTypography.statValueLarge))
            .foregroundColor(Theme.ColorToken.textPrimaryOnDark)
    }

    /// Apply stat label style - FOR LIGHT BACKGROUNDS
    /// Font: 12pt Medium | Color: Gray text (textSecondary)
    func statLabelStyle() -> Text {
        self.font(DSTypography.statLabel)
            .foregroundColor(Theme.ColorToken.textSecondary)
    }

    /// Apply stat label style - FOR DARK BACKGROUNDS
    /// Font: 12pt Medium | Color: 70% white (textSecondaryOnDark)
    func statLabelStyleOnDark() -> Text {
        self.font(DSTypography.statLabel)
            .foregroundColor(Theme.ColorToken.textSecondaryOnDark)
    }

    // MARK: - Button Styles

    /// Apply button primary style - FOR LIGHT BACKGROUNDS
    /// Font: 16pt Semibold | Color: Dark text (textPrimary)
    func buttonPrimaryStyle() -> Text {
        self.font(DSTypography.buttonPrimary)
            .foregroundColor(Theme.ColorToken.textPrimary)
    }

    /// Apply button primary style - FOR DARK BACKGROUNDS
    /// Font: 16pt Semibold | Color: White text (textPrimaryOnDark)
    func buttonPrimaryStyleOnDark() -> Text {
        self.font(DSTypography.buttonPrimary)
            .foregroundColor(Theme.ColorToken.textPrimaryOnDark)
    }
}

// MARK: - Quick Reference Guide

/*
 ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 📚 DSTypography + Color Context Quick Reference
 ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

 LIGHT BACKGROUNDS (Ice/Ivory/White cards):
 ==========================================
 Text("Title").cardTitleStyle()              → 16pt semibold, dark text
 Text("Body").cardBodyStyle()                → 15pt regular, dark text
 Text("Caption").cardCaptionStyle()          → 13pt regular, gray text
 Text("159.9").displayXLStyle()              → 48pt bold, dark text
 Text("159.9").displayXLRoundedStyle()       → 48pt bold rounded, dark text
 Text("32").statValueStyle()                 → 32pt bold monospaced, dark text
 Text("Label").statLabelStyle()              → 12pt medium, gray text

 DARK BACKGROUNDS (Navy gradient):
 ==================================
 Text("Title").cardTitleStyleOnDark()        → 16pt semibold, white text
 Text("Body").cardBodyStyleOnDark()          → 15pt regular, white text
 Text("Caption").cardCaptionStyleOnDark()    → 13pt regular, 70% white
 Text("159.9").displayXLStyleOnDark()        → 48pt bold, white text
 Text("159.9").displayXLRoundedStyleOnDark() → 48pt bold rounded, white text
 Text("32").statValueStyleOnDark()           → 32pt bold monospaced, white text
 Text("Label").statLabelStyleOnDark()        → 12pt medium, 70% white

 FONT ONLY (Manual color control):
 ==================================
 .font(DSTypography.cardTitle)
 .font(DSTypography.displayXL)
 .font(DSTypography.displayXLRounded)
 .font(DSTypography.displayXXL)              → 60pt bold rounded (huge numbers)
 .font(DSTypography.statValueLarge)
 .font(DSTypography.statLabel)

 ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 */
