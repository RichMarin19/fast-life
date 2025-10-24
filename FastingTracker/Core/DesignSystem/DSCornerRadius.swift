import SwiftUI

// MARK: - Design System Corner Radius

/// Centralized corner radius values for consistent UI across all components
/// Industry Pattern: Design Tokens (Apple HIG, Material Design, Figma)
/// Reference: https://developer.apple.com/design/human-interface-guidelines/layout
///
/// SINGLE SOURCE OF TRUTH: All corner radius values defined here
/// Never hardcode corner radius values in components - always reference DSCornerRadius
///
/// APPLE HIG 2025 STANDARDS:
/// - Buttons: 8pt (standard touch target corners)
/// - Cards: 12pt (container elements, moderate rounding)
/// - Banners/Sheets: 14pt (prominent UI elements)
/// - Modals/Dialogs: 16pt (full-screen overlays)
/// - Circular: 999pt (fully rounded, independent of size)
///
/// Usage:
/// ```
/// RoundedRectangle(cornerRadius: DSCornerRadius.card)
/// .cornerRadius(DSCornerRadius.button)
/// Circle() // Use DSCornerRadius.circle for size-independent rounding
/// ```
enum DSCornerRadius {
    // MARK: - Button Corner Radius

    /// Standard button corner radius (8pt)
    /// Used by: Primary buttons, secondary buttons, action buttons, CTA elements
    /// Apple HIG 2025: Standard for interactive touch targets
    static let button: CGFloat = 8

    // MARK: - Card Corner Radius

    /// Standard card container corner radius (12pt)
    /// Used by: DSCard, all card containers, stat cards, tracker cards
    /// Apple HIG 2025: Standard for card-based layouts
    static let card: CGFloat = 12

    /// Small card corner radius (10pt)
    /// Used by: Compact cards, list items with rounded corners, inline cards
    /// Usage: Tighter layouts where 12pt feels too round
    static let cardSmall: CGFloat = 10

    // MARK: - Banner Corner Radius

    /// Banner and coaching bar corner radius (14pt)
    /// Used by: DSBanner, DSCoachBar, ProgressBanner, ReflectionNudge, RecapRow
    /// Design Decision: Slightly more rounded than cards for visual hierarchy
    static let banner: CGFloat = 14

    // MARK: - Modal Corner Radius

    /// Modal and sheet corner radius (16pt)
    /// Used by: Full-screen sheets, confirmation dialogs, settings panels
    /// Apple HIG: iOS modal sheets use 16pt corners
    static let modal: CGFloat = 16

    /// Alert dialog corner radius (14pt)
    /// Used by: Alert dialogs, confirmation popups, contextual dialogs
    /// Apple HIG: System alerts use 14pt corners
    static let alert: CGFloat = 14

    // MARK: - Special Cases

    /// Progress ring corner radius (999pt - fully circular)
    /// Used by: DSProgressRing, circular progress indicators, profile images
    /// Note: Use 999pt instead of calculating actual circle radius for size independence
    static let circle: CGFloat = 999

    /// Pill shape corner radius (999pt - fully rounded ends)
    /// Used by: Pill-shaped buttons, tags, badges, compact toggles
    /// Note: Same as circle - SwiftUI handles pill shape automatically
    static let pill: CGFloat = 999

    // MARK: - Component-Specific Corner Radius

    /// Text field corner radius (8pt)
    /// Used by: Input fields, search bars, text entry components
    /// Apple HIG: Matches button corner radius for form consistency
    static let textField: CGFloat = 8

    /// Image corner radius (10pt)
    /// Used by: Thumbnail images, avatar containers, media previews
    /// Design Decision: Softer than buttons but tighter than cards
    static let image: CGFloat = 10

    /// Chat bubble corner radius (18pt)
    /// Used by: Message bubbles in LifeGPT chat interface
    /// Design Decision: More rounded than cards for friendly, conversational feel
    /// Reference: iMessage (20pt), WhatsApp (18pt) - industry standard
    static let chatBubble: CGFloat = 18
}

// MARK: - View Extension for Corner Radius

extension View {
    /// Apply standard button corner radius (8pt)
    func buttonCornerRadius() -> some View {
        self.cornerRadius(DSCornerRadius.button)
    }

    /// Apply standard card corner radius (12pt)
    func cardCornerRadius() -> some View {
        self.cornerRadius(DSCornerRadius.card)
    }

    /// Apply banner corner radius (14pt)
    func bannerCornerRadius() -> some View {
        self.cornerRadius(DSCornerRadius.banner)
    }

    /// Apply modal corner radius (16pt)
    func modalCornerRadius() -> some View {
        self.cornerRadius(DSCornerRadius.modal)
    }

    /// Apply circular corner radius (999pt)
    func circularCornerRadius() -> some View {
        self.cornerRadius(DSCornerRadius.circle)
    }
}

// MARK: - Shape Extension for Corner Radius

extension RoundedRectangle {
    /// Create rounded rectangle with standard button corner radius (8pt)
    static var button: RoundedRectangle {
        RoundedRectangle(cornerRadius: DSCornerRadius.button, style: .continuous)
    }

    /// Create rounded rectangle with standard card corner radius (12pt)
    static var card: RoundedRectangle {
        RoundedRectangle(cornerRadius: DSCornerRadius.card, style: .continuous)
    }

    /// Create rounded rectangle with banner corner radius (14pt)
    static var banner: RoundedRectangle {
        RoundedRectangle(cornerRadius: DSCornerRadius.banner, style: .continuous)
    }

    /// Create rounded rectangle with modal corner radius (16pt)
    static var modal: RoundedRectangle {
        RoundedRectangle(cornerRadius: DSCornerRadius.modal, style: .continuous)
    }
}

// MARK: - Quick Reference Guide

/*
 ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 📚 DSCornerRadius Quick Reference
 ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

 CORNER RADIUS TOKENS:
 =====================
 DSCornerRadius.button       → 8pt  (buttons, text fields)
 DSCornerRadius.card         → 12pt (cards, containers)
 DSCornerRadius.cardSmall    → 10pt (compact cards, list items)
 DSCornerRadius.banner       → 14pt (banners, coaching bars)
 DSCornerRadius.alert        → 14pt (alert dialogs)
 DSCornerRadius.modal        → 16pt (sheets, full-screen modals)
 DSCornerRadius.circle       → 999pt (circular elements)
 DSCornerRadius.pill         → 999pt (pill-shaped buttons)
 DSCornerRadius.textField    → 8pt  (input fields)
 DSCornerRadius.image        → 10pt (thumbnails, avatars)

 VIEW EXTENSIONS (Convenience):
 ==============================
 .buttonCornerRadius()       → Apply 8pt corner radius
 .cardCornerRadius()         → Apply 12pt corner radius
 .bannerCornerRadius()       → Apply 14pt corner radius
 .modalCornerRadius()        → Apply 16pt corner radius
 .circularCornerRadius()     → Apply 999pt corner radius

 SHAPE EXTENSIONS (Static Factories):
 ====================================
 RoundedRectangle.button     → 8pt rounded rectangle
 RoundedRectangle.card       → 12pt rounded rectangle
 RoundedRectangle.banner     → 14pt rounded rectangle
 RoundedRectangle.modal      → 16pt rounded rectangle

 USAGE EXAMPLES:
 ===============
 // Direct token reference
 .cornerRadius(DSCornerRadius.card)

 // View extension (convenience)
 Button { } .buttonCornerRadius()

 // Shape factory
 RoundedRectangle.card
     .fill(Color.blue)

 // Custom shape
 RoundedRectangle(cornerRadius: DSCornerRadius.banner, style: .continuous)

 ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

 INDUSTRY STANDARDS:
 ===================
 - Apple HIG 2025: 8pt buttons, 12pt cards, 16pt modals
 - Material Design 3: 8dp small, 12dp medium, 16dp large
 - iOS System UI: Consistent corner radii for visual hierarchy

 ANTI-PATTERNS (DO NOT DO):
 ==========================
 ❌ .cornerRadius(12)           // Hardcoded - use DSCornerRadius.card
 ❌ .cornerRadius(8)            // Hardcoded - use DSCornerRadius.button
 ❌ .clipShape(Circle())        // Use .circularCornerRadius() for consistency

 ✅ CORRECT PATTERNS:
 ====================
 ✅ .cornerRadius(DSCornerRadius.card)
 ✅ .cardCornerRadius()
 ✅ RoundedRectangle.card

 ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 */
