import SwiftUI

// MARK: - Design System Card

/// Universal card container with standardized styling and controls
/// Industry Pattern: Component Library (Apple Health, Spotify, Airbnb)
/// Reference: Apple HIG - Cards & Lists
///
/// REPLACES: UniversalCardContainer (Layer 2 prototype)
/// IMPROVES: Separation of concerns - header is separate DSCardHeader component
///
/// STANDARDIZED FEATURES:
/// ✅ Consistent corner radius (16pt)
/// ✅ Consistent shadow (soft, luxury feel)
/// ✅ Consistent padding (16pt)
/// ✅ Eye-slash dismiss button (Layer 3) via DSCardHeader
/// 🔜 Expand/collapse capability (Layer 4) via DSCardHeader
/// 🔜 Drag handle for reordering (Layer 5) via DSCardHeader
///
/// CRITICAL: Content must be PURE (no styling)
/// - No .padding() in content
/// - No .background() in content
/// - No .shadow() in content
/// - No .cornerRadius() in content
/// All styling comes from DSCard container
///
/// Usage:
/// ```
/// DSCard(
///     cardType: .currentWeight,
///     onDismiss: { cardManager.hideCard(.currentWeight) }
/// ) {
///     // PURE CONTENT ONLY - No styling!
///     VStack(spacing: 8) {
///         Text("159.9").font(.system(size: 48, weight: .bold))
///         Text("Latest Weight").font(.caption)
///     }
/// }
/// ```
struct DSCard<Content: View>: View {
    // MARK: - Properties

    /// Card type for tracking
    let cardType: TrackerCardType

    /// Optional custom title (if nil, uses cardType.displayName)
    let title: String?

    /// Optional subtitle
    let subtitle: String?

    /// Optional surface color for light backgrounds (ice/ivory/mint)
    /// When nil, uses default white background
    let surface: Color?

    /// Card content (MUST be pure - no styling!)
    let content: Content

    /// Dismiss action
    let onDismiss: (() -> Void)?

    /// Expand/collapse action (Layer 4)
    let onToggleExpand: (() -> Void)?

    /// Is card expanded? (Layer 4)
    let isExpanded: Bool

    /// Can show dismiss button?
    let canDismiss: Bool

    /// Can show expand/collapse button? (Layer 4)
    let canExpand: Bool

    /// Can show drag handle? (Layer 5)
    let canReorder: Bool

    // MARK: - Initialization

    init(
        cardType: TrackerCardType,
        title: String? = nil,
        subtitle: String? = nil,
        surface: Color? = nil,  // Optional light surface color
        onDismiss: (() -> Void)? = nil,
        onToggleExpand: (() -> Void)? = nil,
        isExpanded: Bool = true,
        canDismiss: Bool = true,
        canExpand: Bool = false,  // Layer 4: Not yet implemented
        canReorder: Bool = false,  // Layer 5: Not yet implemented
        @ViewBuilder content: () -> Content
    ) {
        self.cardType = cardType
        self.title = title
        self.subtitle = subtitle
        self.surface = surface
        self.onDismiss = onDismiss
        self.onToggleExpand = onToggleExpand
        self.isExpanded = isExpanded
        self.canDismiss = canDismiss
        self.canExpand = canExpand
        self.canReorder = canReorder
        self.content = content()
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // HEADER: DSCardHeader component (Layer 3 controls)
            DSCardHeader(
                title: title ?? cardType.displayName,
                subtitle: subtitle,
                onDismiss: onDismiss,
                onToggleExpand: onToggleExpand,
                isExpanded: isExpanded,
                canDismiss: canDismiss,
                canExpand: canExpand,
                canReorder: canReorder
            )

            // CONTENT: Pure content component (NO styling allowed!)
            if isExpanded {
                content
                    .frame(maxWidth: .infinity)  // Full width
            }
        }
        .padding(DSSpacing.cardPadding)  // UNIVERSAL PADDING: 16pt
        .background(surface ?? Theme.ColorToken.card)  // Light surface or default white
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))  // UNIVERSAL RADIUS: 16pt
        .shadow(
            color: Theme.ColorToken.shadowCard,  // UNIVERSAL SHADOW
            radius: 16,
            x: 0,
            y: 8
        )
    }
}

// MARK: - Convenience Initializers

extension DSCard {
    /// Create card with TrackerCardManager integration
    /// Automatically wires up dismiss action to hide card
    init(
        cardType: TrackerCardType,
        title: String? = nil,
        subtitle: String? = nil,
        surface: Color? = nil,  // Optional light surface color
        cardManager: TrackerCardManager = .shared,
        canExpand: Bool = false,
        canReorder: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.init(
            cardType: cardType,
            title: title,
            subtitle: subtitle,
            surface: surface,
            onDismiss: { cardManager.hideCard(cardType) },
            onToggleExpand: canExpand ? { cardManager.toggleCardExpansion(cardType) } : nil,
            isExpanded: cardManager.isCardExpanded(cardType),
            canDismiss: true,
            canExpand: canExpand,
            canReorder: canReorder,
            content: content
        )
    }
}

// MARK: - Preview

#Preview("Current Weight Card - Simple") {
    ZStack {
        Theme.ColorToken.bgDeepStart
            .ignoresSafeArea()

        DSCard(
            cardType: .currentWeight,
            onDismiss: { Log.debug("Dismiss tapped", category: .general) }
        ) {
            VStack(spacing: 8) {
                Text("159.9")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(Theme.ColorToken.textPrimary)

                Text("Latest Weight")
                    .font(DSTypography.cardCaption)
                    .foregroundColor(Theme.ColorToken.textSecondary)
            }
        }
        .padding(.horizontal, DSSpacing.screenEdgePadding)
    }
}

#Preview("Milestone Card - With Subtitle") {
    ZStack {
        Theme.ColorToken.bgDeepStart
            .ignoresSafeArea()

        DSCard(
            cardType: .milestone,
            subtitle: "6 of 10 completed",
            onDismiss: { Log.debug("Dismiss tapped", category: .general) }
        ) {
            VStack(spacing: 16) {
                Circle()
                    .stroke(Theme.ColorToken.accentPrimary, lineWidth: 12)
                    .frame(width: 100, height: 100)
                    .overlay(
                        Text("65%")
                            .font(DSTypography.displayM)
                            .foregroundColor(Theme.ColorToken.textPrimary)
                    )

                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Start")
                            .font(DSTypography.statLabel)
                            .foregroundColor(Theme.ColorToken.textSecondary)
                        Text("180 lb")
                            .font(DSTypography.statValueSmall)
                            .foregroundColor(Theme.ColorToken.textPrimary)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Progress")
                            .font(DSTypography.statLabel)
                            .foregroundColor(Theme.ColorToken.textSecondary)
                        Text("-20.1 lb")
                            .font(DSTypography.statValueSmall)
                            .foregroundColor(Theme.ColorToken.stateSuccess)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("To Go")
                            .font(DSTypography.statLabel)
                            .foregroundColor(Theme.ColorToken.textSecondary)
                        Text("10.9 lb")
                            .font(DSTypography.statValueSmall)
                            .foregroundColor(Theme.ColorToken.accentPrimary)
                    }
                }
            }
        }
        .padding(.horizontal, DSSpacing.screenEdgePadding)
    }
}

#Preview("Card with All Controls - Layer 5") {
    ZStack {
        Theme.ColorToken.bgDeepStart
            .ignoresSafeArea()

        DSCard(
            cardType: .currentWeight,
            subtitle: "Last updated today",
            onDismiss: { Log.debug("Dismiss tapped", category: .general) },
            onToggleExpand: { Log.debug("Toggle expand tapped", category: .general) },
            isExpanded: true,
            canDismiss: true,
            canExpand: true,
            canReorder: true
        ) {
            VStack(spacing: 8) {
                Text("159.9")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(Theme.ColorToken.textPrimary)

                Text("This card has all Layer 5 controls")
                    .font(DSTypography.cardCaption)
                    .foregroundColor(Theme.ColorToken.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, DSSpacing.screenEdgePadding)
    }
}
