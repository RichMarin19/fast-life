import SwiftUI

// MARK: - Universal Card Container

/// Universal wrapper that standardizes all tracker cards
/// Industry Pattern: Decorator pattern for consistent UI (Material Design, Apple Health)
/// Reference: Apple HIG - Cards & Lists
///
/// STANDARDIZED FEATURES:
/// - Consistent corner radius (16pt per Theme.Radius.card)
/// - Consistent shadow (Theme.ColorToken.shadowCard)
/// - Consistent padding from edges (Theme.Spacing.pad = 16pt)
/// - Eye-slash dismiss button (Layer 3)
/// - Expand/collapse capability (Layer 4)
/// - Drag handle for reordering (Layer 5)
///
/// IMPORTANT: This is a WRAPPER - it doesn't change card content,
/// just adds standardized chrome around it.
struct UniversalCardContainer<Content: View>: View {
    // MARK: - Properties

    /// Card type for tracking
    let cardType: TrackerCardType

    /// Card content (the actual card view)
    let content: Content

    /// Optional custom title (if nil, uses cardType.displayName)
    let title: String?

    /// Card manager for state
    @ObservedObject private var cardManager = TrackerCards.shared

    // MARK: - Initialization

    init(
        cardType: TrackerCardType,
        title: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.cardType = cardType
        self.title = title
        self.content = content()
    }

    // MARK: - Body

    var body: some View {
        // For Layer 2: Just render content with standardized styling
        // No header yet - that comes in Layer 3+
        content
            .frame(maxWidth: .infinity)  // Full width
            .padding(Theme.Spacing.pad)  // UNIVERSAL PADDING: 16pt
            .background(Theme.ColorToken.card)  // UNIVERSAL BACKGROUND: White
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))  // UNIVERSAL RADIUS: 16pt
            .shadow(
                color: Theme.ColorToken.shadowCard,  // UNIVERSAL SHADOW
                radius: 16,
                x: 0,
                y: 8
            )
    }
}

// MARK: - Preview

#Preview("Current Weight Card Wrapped") {
    // Example: CurrentWeightCard wrapped in UniversalCardContainer
    // Should look IDENTICAL to current styling
    ZStack {
        Color(red: 10/255, green: 18/255, blue: 36/255)
            .ignoresSafeArea()

        UniversalCardContainer(cardType: .currentWeight) {
            VStack(spacing: 8) {
                Text("159.9")
                    .font(.system(size: 48, weight: .bold))
                Text("Latest Weight")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 20)
    }
}

#Preview("Milestone Card Wrapped") {
    // Example: Milestone-style card wrapped
    ZStack {
        Color(red: 10/255, green: 18/255, blue: 36/255)
            .ignoresSafeArea()

        UniversalCardContainer(cardType: .milestone) {
            VStack(spacing: 16) {
                Text("Milestone 6/10")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Theme.ColorToken.textPrimary)

                Circle()
                    .stroke(Theme.ColorToken.accentPrimary, lineWidth: 12)
                    .frame(width: 100, height: 100)
            }
        }
        .padding(.horizontal, 20)
    }
}
