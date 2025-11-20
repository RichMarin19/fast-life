import SwiftUI

struct CoachBar: View {
    let text: String  // State-based micro-copy
    var icon: String = "sparkles"  // SF Symbol name (default: sparkles)
    let onHide: () -> Void  // Hide callback

    var body: some View {
        DSCoachBar(
            text: text,
            icon: icon,
            backgroundColor: Theme.ColorToken.accentInfo,
            onHide: onHide
        )
    }
}

/// Progress Banner - Motivational/Action message with accent stripe
/// Per Stacked v1.2 spec: Frosted glass background with eye.slash dismiss on RIGHT (matching DSCard pattern)
/// ✅ REUSABLE across all trackers - just pass text + accent color
/// Updated: Eye-slash moved from LEFT to RIGHT to match DSCardHeader
/// v1.2e: Refactored to use DSBanner component for uniform container sizing
