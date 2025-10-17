import SwiftUI

/// ScrollingGradientBackground - Luxury deep gradient background with scroll-aware brightness
/// Implements premium feel with subtle animation following Stripe/Linear design patterns
/// Reference: FastLIFe_WeightTracker_Luxury_UI_and_ControlSpec.md Section 4
///
/// Industry Standard: Premium apps use subtle gradient shifts to create depth
/// Apple Reference: https://developer.apple.com/design/human-interface-guidelines/color#Gradients
struct ScrollingGradientBackground: View {
    /// Accessibility setting - reduce motion
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    /// Scroll phase from 0...1 representing scroll offset
    /// 0 = top of scroll, 1 = fully scrolled
    var phase: CGFloat

    var body: some View {
        // Apply scroll phase with accessibility consideration
        // Industry Standard: Respect user's motion preferences (WCAG 2.1)
        let adjustedPhase = reduceMotion ? 0 : min(max(phase, 0), 1)

        // Deep gradient with subtle brightness shift (≤10% as per spec)
        // Creates sense of depth without distracting from content
        LinearGradient(
            gradient: Gradient(colors: [
                Theme.ColorToken.bgDeepStart.opacity(1 - 0.05 * adjustedPhase),
                Theme.ColorToken.bgDeepEnd.opacity(1 - 0.10 * adjustedPhase)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

// MARK: - PreferenceKey for Scroll Offset Tracking

/// ScrollOffsetPreferenceKey - Tracks scroll offset for gradient phase calculation
/// Industry Standard: Preference keys for cross-view communication in SwiftUI
/// Apple Reference: https://developer.apple.com/documentation/swiftui/preferencekey
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Preview

#Preview {
    struct PreviewContainer: View {
        @State private var scrollPhase: CGFloat = 0

        var body: some View {
            ZStack {
                ScrollingGradientBackground(phase: scrollPhase)

                VStack {
                    Text("Scroll Phase: \(scrollPhase, specifier: "%.2f")")
                        .foregroundColor(Theme.ColorToken.textPrimary)
                        .font(Theme.Font.headline())
                        .padding()
                        .background(Theme.ColorToken.card.opacity(0.8))
                        .cornerRadius(Theme.Radius.chip)
                        .padding(.top, 50)

                    Spacer()

                    ScrollView {
                        VStack(spacing: 20) {
                            ForEach(0..<20) { index in
                                RoundedRectangle(cornerRadius: Theme.Radius.card)
                                    .fill(Theme.ColorToken.card)
                                    .frame(height: 100)
                                    .overlay(
                                        Text("Card \(index + 1)")
                                            .foregroundColor(Theme.ColorToken.textInverse)
                                            .font(Theme.Font.headline())
                                    )
                                    .padding(.horizontal)
                            }
                        }
                        .background(GeometryReader { geometry in
                            Color.clear.preference(
                                key: ScrollOffsetPreferenceKey.self,
                                value: -geometry.frame(in: .named("scroll")).minY
                            )
                        })
                    }
                    .coordinateSpace(name: "scroll")
                    .onPreferenceChange(ScrollOffsetPreferenceKey.self) { offset in
                        // Convert offset to 0...1 phase
                        // Using 800pt as reference scroll distance (adjustable per design)
                        scrollPhase = min(max(offset / 800, 0), 1)
                    }
                }
            }
        }
    }

    return PreviewContainer()
}
