import SwiftUI

/// Fast LIFe Design System following Apple's semantic color approach
/// References Asset Catalog colors for automatic dark/light mode support
/// Reference: https://developer.apple.com/documentation/xcode/specifying-your-apps-color-scheme
struct FLTheme {

    // MARK: - Colors (Semantic Asset Catalog References)

    struct Colors {
        /// Primary brand color - references Asset Catalog with dark/light variants
        static let primary = Color("FLPrimary")

        /// Secondary brand color - references Asset Catalog with dark/light variants
        static let secondary = Color("FLSecondary")

        /// Success state color - references Asset Catalog with dark/light variants
        static let success = Color("FLSuccess")

        /// Warning state color - references Asset Catalog with dark/light variants
        static let warning = Color("FLWarning")

        // Use system colors for other semantic purposes following Apple HIG
        static let background = Color(UIColor.systemBackground)
        static let secondaryBackground = Color(UIColor.secondarySystemBackground)
        static let textPrimary = Color(UIColor.label)
        static let textSecondary = Color(UIColor.secondaryLabel)
    }

    // MARK: - Gradients (Fasting Progress System)

    struct Gradients {
        /// Fasting progress gradient - blue to green progression
        static let fastingProgress = LinearGradient(
            colors: [
                Color(red: 0.2, green: 0.6, blue: 0.9),   // 0%: Blue (start)
                Color(red: 0.2, green: 0.7, blue: 0.8),   // 25%: Teal
                Color(red: 0.2, green: 0.8, blue: 0.7),   // 50%: Cyan
                Color(red: 0.3, green: 0.8, blue: 0.5),   // 75%: Green-teal
                Color(red: 0.4, green: 0.9, blue: 0.4),   // 90%: Vibrant green
                Color(red: 0.3, green: 0.85, blue: 0.3)   // 100%: Celebration green
            ],
            startPoint: .leading,
            endPoint: .trailing
        )

        /// Individual fasting progress colors for discrete use
        static let fastingStage0 = Color(red: 0.2, green: 0.6, blue: 0.9)    // Blue (start)
        static let fastingStage25 = Color(red: 0.2, green: 0.7, blue: 0.8)   // Teal
        static let fastingStage50 = Color(red: 0.2, green: 0.8, blue: 0.7)   // Cyan
        static let fastingStage75 = Color(red: 0.3, green: 0.8, blue: 0.5)   // Green-teal
        static let fastingStage90 = Color(red: 0.4, green: 0.9, blue: 0.4)   // Vibrant green
        static let fastingStage100 = Color(red: 0.3, green: 0.85, blue: 0.3) // Celebration green
    }

    // MARK: - Typography (Following Apple's Dynamic Type)

    struct Typography {
        static let largeTitle = Font.largeTitle.bold()
        static let title = Font.title.bold()
        static let title2 = Font.title2.semibold()
        static let title3 = Font.title3.semibold()
        static let headline = Font.headline
        static let body = Font.body
        static let callout = Font.callout
        static let subheadline = Font.subheadline
        static let footnote = Font.footnote
        static let caption = Font.caption
        static let caption2 = Font.caption2
    }

    // MARK: - Spacing (Following Apple's 8pt Grid System)

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

// MARK: - Convenience Extensions

extension Color {
    /// Fast LIFe semantic colors
    static let fl = FLTheme.Colors.self
}

extension LinearGradient {
    /// Fast LIFe gradients
    static let fl = FLTheme.Gradients.self
}