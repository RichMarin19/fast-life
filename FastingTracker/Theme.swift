import SwiftUI

/// Theme - Centralized design token system for Fast LIFe
/// Luxury UI design system with semantic color tokens
/// Reference: FastLIFe_WeightTracker_Luxury_UI_and_ControlSpec.md
///
/// Industry Standard: Design tokens provide single source of truth
/// Apple Reference: https://developer.apple.com/design/human-interface-guidelines/color
enum Theme {
    // MARK: - Color Tokens

    /// Color tokens following luxury design system
    /// All hex values defined here - NEVER use raw hex in UI code
    enum ColorToken {
        // MARK: Background Colors (Stacked v1.2 - Authoritative)
        // NOTE: bgDeepStart/Mid/End defined below in Global Background Palette section

        // MARK: Surface Colors

        /// Card surface - Pure white (#FFFFFF)
        /// Usage: Primary card backgrounds on dark gradient
        static let card = Color(flHex: "#FFFFFF")

        /// Alternate surface - Light gray (#F7F8FA)
        /// Usage: Secondary card backgrounds, subtle elevation
        static let cardAlt = Color(flHex: "#F7F8FA")

        // MARK: Dark Mode Surface Colors (Control Center)

        /// Card surface on dark gradient - Semi-transparent white (12% opacity)
        /// Usage: Card backgrounds over dark gradient (Control Center)
        /// Creates glass-morphism effect with depth
        static let cardOnDark = Color.white.opacity(0.12)

        /// Card header on dark gradient - Semi-transparent white (8% opacity)
        /// Usage: Card header backgrounds within cardOnDark
        /// Subtle differentiation from card body
        static let cardHeaderOnDark = Color.white.opacity(0.08)

        // MARK: Text Colors (Optimized for Light Surfaces - Stacked v1.2)

        /// Primary text - Deep navy (#0E1B2A)
        /// Usage: Primary text on light card surfaces
        /// Contrast: ≥4.5:1 on light surfaces (WCAG AA compliant)
        static let textPrimary = Color(flHex: "#0E1B2A")

        /// Secondary text - Slate gray (#475569)
        /// Usage: Supporting text, metadata on light surfaces
        static let textSecondary = Color(flHex: "#475569")

        /// Text on dark backgrounds - Light blue-gray (#E8EEF5)
        /// Usage: Text on deep gradient backgrounds (when needed)
        /// Contrast: ≥4.5:1 on bgDeepStart (WCAG AA compliant)
        static let textOnDark = Color(flHex: "#E8EEF5")

        // MARK: Dark Mode Text Colors (Control Center)

        /// Primary text on dark surfaces - Pure white with slight opacity
        /// Usage: Primary text on semi-transparent cards over dark gradients
        /// Contrast: High visibility on dark overlay cards
        static let textPrimaryOnDark = Color.white

        /// Secondary text on dark surfaces - White 70% opacity
        /// Usage: Supporting text, metadata on dark overlay cards
        static let textSecondaryOnDark = Color.white.opacity(0.7)

        // MARK: Accent Colors

        /// Primary accent - Emerald green (#1ABC9C)
        /// Usage: Primary actions, progress indicators, success states
        static let accentPrimary = Color(flHex: "#1ABC9C")

        /// Gold accent - Rich gold (#D4AF37)
        /// Usage: Achievement badges, premium features, "New Low" indicators
        static let accentGold = Color(flHex: "#D4AF37")

        /// Info accent - Royal blue (#2E86DE)
        /// Usage: Goal lines, informational elements, links
        static let accentInfo = Color(flHex: "#2E86DE")

        // MARK: Global Background Palette (Stacked v1.2)
        // Reference: FastLIFe_ProgressStory_Stacked_v1.2_Light_OptOut.md
        // Authoritative palette for entire app (all trackers)

        /// Background gradient start - Deep navy (#0C1A2B)
        /// Usage: Primary gradient background (top)
        /// Emotion: Calm, trust, depth
        static let bgDeepStart = Color(flHex: "#0C1A2B")

        /// Background gradient mid - Medium navy (#0F2438)
        /// Usage: Primary gradient background (middle)
        /// Creates visual breathing effect
        static let bgDeepMid = Color(flHex: "#0F2438")

        /// Background gradient end - Rich navy (#123449)
        /// Usage: Primary gradient background (bottom)
        /// Adds depth to scrolling background
        static let bgDeepEnd = Color(flHex: "#123449")

        // MARK: Light Card Surfaces (Stacked v1.2)
        // Light, airy surfaces for luxury + optimism contrast

        /// Ice surface - Cool light (#F4FAFD)
        /// Usage: 7-day trend cards, primary light cards
        /// Emotion: Fresh, clarity, focus
        static let surfaceIce = Color(flHex: "#F4FAFD")

        /// Ivory surface - Warm light (#FEF9F3)
        /// Usage: 30-day trend cards, secondary light cards
        /// Emotion: Warmth, achievement, growth
        static let surfaceIvory = Color(flHex: "#FEF9F3")

        /// Mint surface - Soft green-tinted light (#F8FFF6)
        /// Usage: Tips, insights, educational content
        /// Emotion: Health, knowledge, calm
        static let surfaceMint = Color(flHex: "#F8FFF6")

        /// Light stroke - Subtle border (rgba(0,0,0,0.06))
        /// Usage: Card borders on light surfaces
        static let strokeLight = Color.black.opacity(0.06)

        // MARK: System State Colors

        /// Success state - Matches accentPrimary
        /// Usage: Successful operations, positive trends
        static let stateSuccess = accentPrimary

        /// Warning state - Amber (#F0B429)
        /// Usage: Caution indicators, approaching limits
        static let stateWarning = Color(flHex: "#F0B429")

        /// Error state - Coral red (#E05252)
        /// Usage: Errors, negative trends, destructive actions
        static let stateError = Color(flHex: "#E05252")

        // MARK: UI Element Colors

        /// Dark divider - Translucent white (8% opacity)
        /// Usage: Separators on dark backgrounds
        static let dividerDark = Color.white.opacity(0.08)

        /// Light divider on dark surfaces - Translucent white (15% opacity)
        /// Usage: Dividers within cards on dark gradients (Control Center)
        /// Higher contrast than dividerDark for nested content
        static let dividerOnDark = Color.white.opacity(0.15)

        /// Card shadow - Translucent black (18% opacity)
        /// Usage: Card drop shadows for elevation
        static let shadowCard = Color.black.opacity(0.18)

        /// Card shadow on dark gradient - Translucent black (30% opacity)
        /// Usage: Card shadows over dark gradients (Control Center)
        /// Stronger shadow for better depth perception
        static let shadowCardOnDark = Color.black.opacity(0.3)

        /// Drag handle color - Semi-transparent white (60% opacity)
        /// Usage: Reorder handles on dark cards (Control Center)
        static let dragHandle = Color.white.opacity(0.6)
    }

    // MARK: - Corner Radius

    /// Corner radius tokens following Apple 2025 standards
    enum Radius {
        /// Card corner radius - 16pt
        /// Usage: Primary cards, panels, large components
        static let card: CGFloat = 16

        /// Chip corner radius - 12pt
        /// Usage: Pills, badges, small interactive elements
        static let chip: CGFloat = 12

        /// Button corner radius - 8pt
        /// Usage: Buttons, text fields (standard Apple size)
        static let button: CGFloat = 8
    }

    // MARK: - Spacing

    /// Spacing tokens for consistent layout
    enum Spacing {
        /// Base spacing unit - 4pt
        /// Usage: Micro spacing, fine adjustments
        static let base: CGFloat = 4

        /// Standard padding - 16pt
        /// Usage: Default horizontal/vertical padding
        static let pad: CGFloat = 16

        /// Card spacing - 12pt
        /// Usage: Space between cards in lists
        static let cardSpacing: CGFloat = 12

        /// Section spacing - 24pt
        /// Usage: Space between major sections
        static let sectionSpacing: CGFloat = 24
    }

    // MARK: - Typography

    /// Font tokens following Apple HIG typography scale
    enum Font {
        /// Headline font - Medium weight, 20pt default
        /// Usage: Section headers, card titles
        static func headline(_ size: CGFloat = 20) -> SwiftUI.Font {
            .system(size: size, weight: .medium)
        }

        /// Body font - Regular weight, 16pt default
        /// Usage: Primary content text, labels
        static func body(_ size: CGFloat = 16) -> SwiftUI.Font {
            .system(size: size, weight: .regular)
        }

        /// Metadata font - Light weight, 13pt default
        /// Usage: Timestamps, auxiliary information
        static func meta(_ size: CGFloat = 13) -> SwiftUI.Font {
            .system(size: size, weight: .light)
        }

        /// Display font - Semibold weight for large hero numbers
        /// Usage: Primary metric display (e.g., current weight)
        static func display(_ size: CGFloat = 44) -> SwiftUI.Font {
            .system(size: size, weight: .semibold)
        }

        /// Title font - Bold weight for screen titles
        /// Usage: Screen headers, navigation titles
        static func title(_ size: CGFloat = 28) -> SwiftUI.Font {
            .system(size: size, weight: .semibold)
        }
    }

    // MARK: - Animation

    /// Animation duration tokens for consistent micro-interactions
    enum Animation {
        /// Quick transition - 180ms
        /// Usage: Button state changes, quick feedback
        static let quick: Double = 0.18

        /// Standard transition - 220ms
        /// Usage: View transitions, standard animations
        static let standard: Double = 0.22

        /// Micro-glow duration - 400ms
        /// Usage: Achievement glow effects
        static let glow: Double = 0.4

        /// Spring dampening - 0.7
        /// Usage: Spring animations for natural motion
        static let springDamping: Double = 0.7
    }

    // MARK: - Tap Targets

    /// Minimum tap target sizes following Apple HIG
    enum TapTarget {
        /// Minimum tap target - 44pt
        /// Apple HIG requirement for accessibility
        static let minimum: CGFloat = 44
    }
}

// MARK: - Color Hex Extension

/// Extension to initialize SwiftUI Color from hex string
/// Supports 3, 6, and 8 character hex codes
/// Industry standard pattern for design token systems
extension Color {
    /// Initialize Color from hex string
    /// - Parameter flHex: Hex color string (e.g., "#1ABC9C", "1ABC9C", "#RGB")
    ///
    /// Supports formats:
    /// - 3 characters: RGB (12-bit)
    /// - 6 characters: RRGGBB (24-bit)
    /// - 8 characters: AARRGGBB (32-bit with alpha)
    init(flHex hex: String) {
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
            (a, r, g, b) = (255, 1, 1, 0)
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

// MARK: - Legacy Theme Support (Backward Compatibility)

/// FLTheme - Legacy theme system for existing code
/// Gradually migrating to Theme.ColorToken system
/// TODO: Remove after full migration to new Theme system
struct FLTheme {
    struct Colors {
        static let primary = Color("FLPrimary")
        static let secondary = Color("FLSecondary")
        static let success = Color("FLSuccess")
        static let warning = Color("FLWarning")
        static let background = Color(UIColor.systemBackground)
        static let secondaryBackground = Color(UIColor.secondarySystemBackground)
        static let textPrimary = Color(UIColor.label)
        static let textSecondary = Color(UIColor.secondaryLabel)
    }

    struct Gradients {
        static let fastingProgress = LinearGradient(
            colors: [
                Color(red: 0.2, green: 0.6, blue: 0.9),
                Color(red: 0.2, green: 0.7, blue: 0.8),
                Color(red: 0.2, green: 0.8, blue: 0.7),
                Color(red: 0.3, green: 0.8, blue: 0.5),
                Color(red: 0.4, green: 0.9, blue: 0.4),
                Color(red: 0.3, green: 0.85, blue: 0.3)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )

        static let fastingStage0 = Color(red: 0.2, green: 0.6, blue: 0.9)
        static let fastingStage25 = Color(red: 0.2, green: 0.7, blue: 0.8)
        static let fastingStage50 = Color(red: 0.2, green: 0.8, blue: 0.7)
        static let fastingStage75 = Color(red: 0.3, green: 0.8, blue: 0.5)
        static let fastingStage90 = Color(red: 0.4, green: 0.9, blue: 0.4)
        static let fastingStage100 = Color(red: 0.3, green: 0.85, blue: 0.3)
    }

    struct Typography {
        static let largeTitle = Font.largeTitle.bold()
        static let title = Font.title.bold()
        static let title2 = Font.title2.weight(.semibold)
        static let title3 = Font.title3.weight(.semibold)
        static let headline = Font.headline
        static let body = Font.body
        static let callout = Font.callout
        static let subheadline = Font.subheadline
        static let footnote = Font.footnote
        static let caption = Font.caption
        static let caption2 = Font.caption2
    }

    struct Spacing {
        static let xxs: CGFloat = 2
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }
}

// Legacy convenience extensions
extension Color {
    static let fl = FLTheme.Colors.self
}

extension LinearGradient {
    static let fl = FLTheme.Gradients.self
}

