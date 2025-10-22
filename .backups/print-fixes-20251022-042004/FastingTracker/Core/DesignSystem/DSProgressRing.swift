import SwiftUI

// MARK: - DSProgressRing (v1.2d - Universal Standardization)

/// DSProgressRing - Reusable circular progress ring component
/// Per Universal Standardization Architecture (Phase v1.2d):
///   - Level 3: Reusable Component (used in multiple custom contents)
///   - Industry Pattern: Apple Watch Activity Rings, Apple Health progress indicators
///   - Extracted from CircularTrendRingCard + MilestoneRingCard to eliminate duplication
///
/// **Usage Locations:**
///   - CircularTrendRingCard (WeightComponents.swift) - 7-day/30-day trend rings
///   - MilestoneRingCard (MilestoneRingCard.swift) - Milestone progress ring
///   - Future: Fasting/Hydration/Sleep/Mood tracker progress rings
///
/// **Design Tokens:**
///   - Uses DSSpacing, DSColors (via Theme.ColorToken), DSTypography
///   - Respects Reduce Motion accessibility setting
///   - Follows Apple HIG for progress indicators
///
/// **Code Savings:**
///   - Eliminates ~60-80 lines of duplicated code
///   - Single source of truth for ring styling/behavior
struct DSProgressRing: View {
    // MARK: - Parameters

    /// Progress value (0.0 - 1.0)
    let progress: CGFloat

    /// Ring diameter in points
    let size: CGFloat

    /// Ring stroke width in points
    let strokeWidth: CGFloat

    /// Progress ring gradient (or solid color via single-color gradient)
    let progressGradient: LinearGradient

    /// Background track color
    let trackColor: Color

    /// Shadow color for ambient glow effect
    let glowColor: Color

    /// Shadow intensity (0.0 - 1.0), multiplied by base opacity
    let glowIntensity: CGFloat

    /// Enable shadow glow effect (disabled on Reduce Motion)
    let enableGlow: Bool

    /// Enable inner halo overlay for additional depth
    let enableHalo: Bool

    /// Animation duration for ring sweep (seconds)
    let animationDuration: Double

    /// Triggered when animation should start (via @State in parent)
    @Binding var animateProgress: Bool

    // MARK: - Accessibility

    @Environment(\.accessibilityReduceMotion) var reduceMotion

    // MARK: - Initialization

    /// Create a progress ring with full customization
    /// - Parameters:
    ///   - progress: Progress value (0.0 - 1.0)
    ///   - size: Ring diameter in points (default: 160)
    ///   - strokeWidth: Ring stroke width in points (default: 12)
    ///   - progressGradient: Gradient for progress ring
    ///   - trackColor: Background track color (default: white 20% opacity)
    ///   - glowColor: Shadow glow color (default: progressGradient start color)
    ///   - glowIntensity: Shadow intensity 0.0-1.0 (default: 0.40)
    ///   - enableGlow: Enable shadow glow (default: true, disabled on Reduce Motion)
    ///   - enableHalo: Enable inner halo overlay (default: true, disabled on Reduce Motion)
    ///   - animationDuration: Animation duration in seconds (default: 1.2)
    ///   - animateProgress: Binding to trigger animation (default: false, set to true to animate)
    init(
        progress: CGFloat,
        size: CGFloat = 160,
        strokeWidth: CGFloat = 12,
        progressGradient: LinearGradient,
        trackColor: Color = Color.white.opacity(0.2),
        glowColor: Color? = nil,
        glowIntensity: CGFloat = 0.40,
        enableGlow: Bool = true,
        enableHalo: Bool = true,
        animationDuration: Double = 1.2,
        animateProgress: Binding<Bool> = .constant(true)
    ) {
        self.progress = progress
        self.size = size
        self.strokeWidth = strokeWidth
        self.progressGradient = progressGradient
        self.trackColor = trackColor
        // If glowColor not provided, use first color from gradient
        self.glowColor = glowColor ?? progressGradient.stops.first?.color ?? .blue
        self.glowIntensity = glowIntensity
        self.enableGlow = enableGlow
        self.enableHalo = enableHalo
        self.animationDuration = animationDuration
        self._animateProgress = animateProgress
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // Background ring (unfilled track)
            Circle()
                .stroke(
                    trackColor,
                    style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round)
                )
                .frame(width: size, height: size)

            // Progress ring (gradient fill with glow)
            // Per v1.2 spec C.2: Enhanced glow for better visibility on light cards
            Circle()
                .trim(from: 0, to: animateProgress ? progress : 0)
                .stroke(
                    progressGradient,
                    style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round)
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))  // Start from top (12 o'clock position)
                .shadow(
                    color: (enableGlow && !reduceMotion) ? glowColor.opacity(glowIntensity) : Color.clear,
                    radius: 20,
                    x: 0,
                    y: 7
                )
                .overlay(
                    // Inner halo for additional depth (v1.2 spec C.2)
                    // Only shown if enableHalo = true AND Reduce Motion = OFF
                    Group {
                        if enableHalo && !reduceMotion {
                            Circle()
                                .stroke(glowColor.opacity(0.08), lineWidth: 1)
                                .blur(radius: 14)
                                .frame(width: size + 20, height: size + 20)
                        }
                    }
                )
                .animation(
                    reduceMotion ? nil : .easeOut(duration: animationDuration),
                    value: animateProgress
                )
        }
    }
}

// MARK: - Convenience Initializers

extension DSProgressRing {
    /// Create a progress ring with solid color (converts to gradient automatically)
    /// - Parameters:
    ///   - progress: Progress value (0.0 - 1.0)
    ///   - size: Ring diameter in points (default: 160)
    ///   - strokeWidth: Ring stroke width in points (default: 12)
    ///   - progressColor: Solid color for progress ring
    ///   - trackColor: Background track color (default: white 20% opacity)
    ///   - glowIntensity: Shadow intensity 0.0-1.0 (default: 0.40)
    ///   - enableGlow: Enable shadow glow (default: true)
    ///   - enableHalo: Enable inner halo overlay (default: true)
    ///   - animationDuration: Animation duration in seconds (default: 1.2)
    ///   - animateProgress: Binding to trigger animation
    init(
        progress: CGFloat,
        size: CGFloat = 160,
        strokeWidth: CGFloat = 12,
        progressColor: Color,
        trackColor: Color = Color.white.opacity(0.2),
        glowIntensity: CGFloat = 0.40,
        enableGlow: Bool = true,
        enableHalo: Bool = true,
        animationDuration: Double = 1.2,
        animateProgress: Binding<Bool> = .constant(true)
    ) {
        // Convert solid color to gradient
        let gradient = LinearGradient(
            colors: [progressColor, progressColor.opacity(0.8)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        self.init(
            progress: progress,
            size: size,
            strokeWidth: strokeWidth,
            progressGradient: gradient,
            trackColor: trackColor,
            glowColor: progressColor,
            glowIntensity: glowIntensity,
            enableGlow: enableGlow,
            enableHalo: enableHalo,
            animationDuration: animationDuration,
            animateProgress: animateProgress
        )
    }
}

// MARK: - Preview

#Preview("Progress Rings - Various States") {
    ZStack {
        // Dark background like Weight Tracker
        Color(red: 10/255, green: 18/255, blue: 36/255)
            .ignoresSafeArea()

        VStack(spacing: 40) {
            // Ring 1: Improving (Teal → Blue gradient)
            DSProgressRing(
                progress: 0.65,
                progressGradient: LinearGradient(
                    colors: [Color(hex: "22D1A3"), Color(hex: "2B86C5")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                Text("65%")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
            )

            // Ring 2: Regressing (Coral → Rose gradient)
            DSProgressRing(
                progress: 0.35,
                size: 140,
                strokeWidth: 10,
                progressGradient: LinearGradient(
                    colors: [Color(hex: "E47A6E"), Color(hex: "D63A3A")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                glowIntensity: 0.30
            )
            .overlay(
                Text("35%")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
            )

            // Ring 3: Solid color (Emerald)
            DSProgressRing(
                progress: 0.85,
                size: 120,
                strokeWidth: 18,
                progressColor: Theme.ColorToken.accentPrimary
            )
            .overlay(
                Text("85%")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
            )
        }
        .padding()
    }
}

// MARK: - Color Extension (hex init)

extension Color {
    /// Initialize Color from hex string
    /// - Parameter hex: Hex string (e.g., "22D1A3" or "#22D1A3")
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
