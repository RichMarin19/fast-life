import SwiftUI

// MARK: - Design System Spacing

/// Centralized spacing constants for consistent layout across all components
/// Industry Pattern: Design Tokens (Apple HIG, Material Design, Figma)
/// Reference: https://developer.apple.com/design/human-interface-guidelines/layout
///
/// SINGLE SOURCE OF TRUTH: All spacing values defined here
/// Never hardcode spacing values in components - always reference DSSpacing
///
/// Usage:
/// ```
/// .padding(DSSpacing.cardPadding)
/// VStack(spacing: DSSpacing.sectionSpacing) { ... }
/// ```
enum DSSpacing {
    // MARK: - Card Spacing

    /// Standard padding inside all cards (16pt)
    /// Used by: DSCard, all card containers
    static let cardPadding: CGFloat = 16

    /// Spacing between card sections (20pt)
    /// Used by: Multi-section cards like CurrentWeightCard
    static let cardSectionSpacing: CGFloat = 20

    /// Spacing between card elements (12pt)
    /// Used by: Elements within a card section
    static let cardElementSpacing: CGFloat = 12

    /// Small spacing for tightly grouped elements (8pt)
    /// Used by: Icon + text, closely related items
    static let cardSmallSpacing: CGFloat = 8

    /// Extra small spacing for very tight elements (4pt)
    /// Used by: Number + unit text, baseline-aligned items
    static let cardExtraSmallSpacing: CGFloat = 4

    // MARK: - Screen Spacing

    /// Horizontal padding from screen edges (20pt)
    /// Used by: All full-width cards in TrackerScreenShell
    /// Note: Cards get .padding(.horizontal, DSSpacing.screenEdgePadding)
    static let screenEdgePadding: CGFloat = 20

    /// Vertical spacing between cards on screen (16pt)
    /// Used by: VStack spacing in main tracker views
    static let cardVerticalSpacing: CGFloat = 16

    // MARK: - Header Spacing

    /// Spacing between header and content (12pt)
    /// Used by: DSCardHeader bottom padding
    static let headerBottomSpacing: CGFloat = 12

    /// Spacing between header elements (8pt)
    /// Used by: Title and controls in header
    static let headerElementSpacing: CGFloat = 8

    // MARK: - Button Spacing

    /// Padding inside buttons (12pt vertical, 16pt horizontal)
    /// Used by: Primary action buttons
    static let buttonPaddingVertical: CGFloat = 12
    static let buttonPaddingHorizontal: CGFloat = 16

    /// Spacing between buttons in button groups (12pt)
    /// Used by: Multiple buttons in a row/column
    static let buttonGroupSpacing: CGFloat = 12

    // MARK: - List Spacing

    /// Spacing between list items (12pt)
    /// Used by: Weight history list, settings list
    static let listItemSpacing: CGFloat = 12

    /// Padding inside list items (12pt)
    /// Used by: List row content padding
    static let listItemPadding: CGFloat = 12

    // MARK: - Progress Ring Spacing
    // Phase 2 Task 2.2: Replace Magic Numbers

    /// Size of circular progress ring (200pt diameter)
    /// Used by: CircularProgressRing in CurrentWeightCard
    static let progressRingSize: CGFloat = 200

    /// Stroke width for progress ring arc (14pt)
    /// Used by: CircularProgressRing background and progress arc
    static let progressRingStrokeWidth: CGFloat = 14

    /// Size of milestone indicator dots (20pt diameter)
    /// Used by: Milestone dots below CircularProgressRing
    static let milestoneDotSize: CGFloat = 20

    /// Vertical padding for progress ring container (20pt)
    /// Used by: CircularProgressRing outer VStack
    static let progressRingPaddingVertical: CGFloat = 20

    /// Horizontal padding for progress ring container (24pt)
    /// Used by: CircularProgressRing outer VStack
    static let progressRingPaddingHorizontal: CGFloat = 24
}
