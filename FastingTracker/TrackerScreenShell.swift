import SwiftUI

/// Gradient style options for TrackerScreenShell
/// Defines visual treatment of tracker background
enum TrackerGradientStyle {
    /// No gradient - standard system background (backward compatible)
    case none

    /// Luxury deep gradient - Premium feel for North Star UI
    /// Deep navy to midnight blue with subtle scroll animation
    case luxury
}

/// TrackerScreenShell - Shared component wrapper for all tracker screens
/// Follows Apple HIG patterns for consistent tracker experience
/// Enhanced with optional luxury gradient support for North Star UI
/// Reference: https://developer.apple.com/design/human-interface-guidelines/patterns
struct TrackerScreenShell<Content: View>: View {
    let title: String
    let titleColor1: Color
    let titleColor2: Color
    let titleColor3: Color
    let hasData: Bool
    let showingNudge: Bool
    let nudgeContent: AnyView?
    let gradientStyle: TrackerGradientStyle
    let settingsAction: () -> Void
    let content: Content

    @State private var scrollPhase: CGFloat = 0

    /// Initialize TrackerScreenShell with title styling and content
    /// - Parameters:
    ///   - title: Three-part title (e.g., "Weight Tr" + "ac" + "ker")
    ///   - titleColors: Three colors for title parts following brand hierarchy
    ///   - hasData: Whether tracker has data (affects title visibility)
    ///   - nudgeContent: Optional HealthKit nudge banner
    ///   - gradientStyle: Background gradient style (.none for standard, .luxury for premium)
    ///   - settingsAction: Settings gear tap action
    ///   - content: Main tracker content view
    init(
        title: (String, String, String),
        titleColors: (Color, Color, Color) = (Color("FLPrimary"), Color("FLSuccess"), Color("FLSecondary")),
        hasData: Bool,
        nudge: AnyView? = nil,
        gradientStyle: TrackerGradientStyle = .none,
        settingsAction: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title.0 + title.1 + title.2
        self.titleColor1 = titleColors.0
        self.titleColor2 = titleColors.1
        self.titleColor3 = titleColors.2
        self.hasData = hasData
        self.showingNudge = nudge != nil
        self.nudgeContent = nudge
        self.gradientStyle = gradientStyle
        self.settingsAction = settingsAction
        self.content = content()
    }

    var body: some View {
        ZStack {
            // Optional luxury gradient background
            // Only rendered when gradientStyle = .luxury
            if gradientStyle == .luxury {
                ScrollingGradientBackground(phase: scrollPhase)
            }

            ScrollView {
                VStack(spacing: 12) {
                    // Professional Title Header (when data exists)
                    // Following Fast LIFe branding pattern
                    if hasData {
                        TrackerTitleView(
                            title: title,
                            titleColor1: gradientStyle == .luxury ? Theme.ColorToken.textPrimary : titleColor1,
                            titleColor2: gradientStyle == .luxury ? Theme.ColorToken.textPrimary : titleColor2,
                            titleColor3: gradientStyle == .luxury ? Theme.ColorToken.textPrimary : titleColor3
                        )
                    }

                    // HealthKit Nudge Banner (contextual)
                    if showingNudge, let nudge = nudgeContent {
                        nudge
                            .padding(.horizontal)
                            .padding(.bottom, 8)
                    }

                    // Main Tracker Content
                    content
                }
                .background(GeometryReader { geometry in
                    // Track scroll offset for gradient phase animation
                    // Only needed for luxury gradient
                    Color.clear.preference(
                        key: ScrollOffsetPreferenceKey.self,
                        value: -geometry.frame(in: .named("trackerScroll")).minY
                    )
                })
            }
            .coordinateSpace(name: "trackerScroll")
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { offset in
                // Convert scroll offset to 0...1 phase for gradient animation
                // 800pt reference distance (adjustable per design)
                if gradientStyle == .luxury {
                    scrollPhase = min(max(offset / 800, 0), 1)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: settingsAction) {
                    // Control Center icon - premium command panel feel
                    // SF Symbol: slider.horizontal.3 communicates control/adjustment
                    // Reference: FastLIFe_WeightTracker_Consolidated_Spec.md §7
                    Image(systemName: "slider.horizontal.3")
                        .foregroundColor(gradientStyle == .luxury ? Theme.ColorToken.textPrimary : Color("FLWarning"))
                        .font(.system(size: 20, weight: .semibold))
                }
                .accessibilityLabel("Control Center")
                .accessibilityHint("Opens tracker control panel with goals, data sync, and guidance settings")
            }
        }
    }
}

/// Reusable Title Component for Trackers
/// Implements Fast LIFe branding with semantic colors OR luxury gradient
/// For luxury style: Uses blue→emerald gradient (Theme.ColorToken.accentInfo → accentPrimary)
/// For standard style: Uses three-color split pattern
private struct TrackerTitleView: View {
    let title: String
    let titleColor1: Color
    let titleColor2: Color
    let titleColor3: Color

    // Detect luxury mode: if all three colors are the same (textPrimary), use gradient
    private var isLuxuryMode: Bool {
        // In luxury mode, TrackerScreenShell passes same color for all three
        titleColor1 == Theme.ColorToken.textPrimary &&
        titleColor2 == Theme.ColorToken.textPrimary &&
        titleColor3 == Theme.ColorToken.textPrimary
    }

    var body: some View {
        if isLuxuryMode {
            // LUXURY MODE: Gradient title per spec
            // Gradient: left→right accent.info → accent.primary
            Text(title)
                .font(.system(size: 34, weight: .bold))
                .kerning(-0.2)
                .foregroundStyle(
                    LinearGradient(
                        colors: [Theme.ColorToken.accentInfo, Theme.ColorToken.accentPrimary],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        } else {
            // STANDARD MODE: Three-color split pattern (backward compatible)
            let parts = splitTitle(title)

            HStack(spacing: 0) {
                Text(parts.0)
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(titleColor1)
                Text(parts.1)
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(titleColor2)
                Text(parts.2)
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(titleColor3)
            }
        }
    }

    /// Split title into three parts for color styling
    /// Default pattern: first part, middle 2 chars, remainder
    private func splitTitle(_ title: String) -> (String, String, String) {
        let chars = Array(title)
        let count = chars.count

        if count <= 3 {
            return (title, "", "")
        }

        let firstPartEnd = max(1, count - 3)
        let secondPartEnd = min(firstPartEnd + 2, count)

        let part1 = String(chars[0..<firstPartEnd])
        let part2 = secondPartEnd > firstPartEnd ? String(chars[firstPartEnd..<secondPartEnd]) : ""
        let part3 = secondPartEnd < count ? String(chars[secondPartEnd..<count]) : ""

        return (part1, part2, part3)
    }
}

// MARK: - Convenience Extensions

// PreferenceKey to pass scroll offset from GeometryReader to parent
private struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

/// Animated scrolling gradient background used for the `.luxury` style
/// The gradient subtly shifts based on the provided `phase` (0...1)
private struct ScrollingGradientBackground: View {
    var phase: CGFloat

    // Colors chosen to evoke a premium, deep look while staying subtle
    private let top = Color(red: 10/255, green: 18/255, blue: 36/255)
    private let mid = Color(red: 18/255, green: 28/255, blue: 56/255)
    private let bottom = Color(red: 4/255, green: 8/255, blue: 18/255)

    var body: some View {
        GeometryReader { proxy in
            let height = max(proxy.size.height, 1)
            // Map phase 0...1 to a small offset to keep motion tasteful
            let offset = phase * height * 0.15

            LinearGradient(
                gradient: Gradient(colors: [top, mid, bottom]),
                startPoint: UnitPoint(x: 0.5, y: max(0, 0.0 + offset / height)),
                endPoint: UnitPoint(x: 0.5, y: min(1, 1.0 + offset / height))
            )
            .ignoresSafeArea()
        }
        .animation(.easeInOut(duration: 0.6), value: phase)
    }
}
