import SwiftUI

/// TrackerScreenShell - Shared component wrapper for all tracker screens
/// Follows Apple HIG patterns for consistent tracker experience
/// Reference: https://developer.apple.com/design/human-interface-guidelines/patterns
struct TrackerScreenShell<Content: View>: View {
    let title: String
    let titleColor1: Color
    let titleColor2: Color
    let titleColor3: Color
    let hasData: Bool
    let showingNudge: Bool
    let nudgeContent: AnyView?
    let settingsAction: () -> Void
    let content: Content

    /// Initialize TrackerScreenShell with title styling and content
    /// - Parameters:
    ///   - title: Three-part title (e.g., "Weight Tr" + "ac" + "ker")
    ///   - titleColors: Three colors for title parts following brand hierarchy
    ///   - hasData: Whether tracker has data (affects title visibility)
    ///   - nudgeContent: Optional HealthKit nudge banner
    ///   - settingsAction: Settings gear tap action
    ///   - content: Main tracker content view
    init(
        title: (String, String, String),
        titleColors: (Color, Color, Color) = (Color("FLPrimary"), Color("FLSuccess"), Color("FLSecondary")),
        hasData: Bool,
        nudge: AnyView? = nil,
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
        self.settingsAction = settingsAction
        self.content = content()
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Professional Title Header (when data exists)
                // Following Fast LIFe branding pattern
                if self.hasData {
                    TrackerTitleView(
                        title: self.title,
                        titleColor1: self.titleColor1,
                        titleColor2: self.titleColor2,
                        titleColor3: self.titleColor3
                    )
                }

                // HealthKit Nudge Banner (contextual)
                if self.showingNudge, let nudge = nudgeContent {
                    nudge
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                }

                // Main Tracker Content
                self.content
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: self.settingsAction) {
                    Image(systemName: "gearshape.fill")
                        .foregroundColor(Color("FLWarning"))
                        .font(.system(size: 20))
                }
            }
        }
    }
}

/// Reusable Title Component for Trackers
/// Implements Fast LIFe branding with semantic colors
private struct TrackerTitleView: View {
    let title: String
    let titleColor1: Color
    let titleColor2: Color
    let titleColor3: Color

    var body: some View {
        let parts = self.splitTitle(self.title)

        HStack(spacing: 0) {
            Text(parts.0)
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundColor(self.titleColor1)
            Text(parts.1)
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundColor(self.titleColor2)
            Text(parts.2)
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundColor(self.titleColor3)
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

        let part1 = String(chars[0 ..< firstPartEnd])
        let part2 = secondPartEnd > firstPartEnd ? String(chars[firstPartEnd ..< secondPartEnd]) : ""
        let part3 = secondPartEnd < count ? String(chars[secondPartEnd ..< count]) : ""

        return (part1, part2, part3)
    }
}

// MARK: - Convenience Extensions
