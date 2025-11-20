import SwiftUI

// MARK: - Design System Card Header

/// Reusable card header with standardized title and controls
/// Industry Pattern: Component Library (Apple Health, Spotify, Airbnb)
/// Reference: Apple HIG - Cards & Lists
///
/// FEATURES:
/// - Title text (left-aligned)
/// - Eye-slash dismiss button (right-aligned) ✅ Layer 3
/// - Expand/collapse chevron (right-aligned) 🔜 Layer 4
/// - Drag handle (left-aligned) 🔜 Layer 5
///
/// Usage:
/// ```
/// DSCardHeader(
///     title: "Current Weight",
///     onDismiss: { cardManager.hideCard(.currentWeight) }
/// )
/// ```
struct DSCardHeader: View {
    // MARK: - Properties

    /// Header title text
    let title: String

    /// Optional subtitle text
    let subtitle: String?

    /// Dismiss action (eye-slash button)
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
        title: String,
        subtitle: String? = nil,
        onDismiss: (() -> Void)? = nil,
        onToggleExpand: (() -> Void)? = nil,
        isExpanded: Bool = true,
        canDismiss: Bool = true,
        canExpand: Bool = false,  // Layer 4: Not yet implemented
        canReorder: Bool = false  // Layer 5: Not yet implemented
    ) {
        self.title = title
        self.subtitle = subtitle
        self.onDismiss = onDismiss
        self.onToggleExpand = onToggleExpand
        self.isExpanded = isExpanded
        self.canDismiss = canDismiss
        self.canExpand = canExpand
        self.canReorder = canReorder
    }

    // MARK: - Body

    var body: some View {
        HStack(spacing: DSSpacing.headerElementSpacing) {
            // LAYER 5: Drag handle (left side)
            if canReorder {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(DSColors.textSecondary)
                    .opacity(0.5)  // More subtle than other controls
            }

            // Title and subtitle
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(DSTypography.cardTitle)
                    .foregroundColor(DSColors.textPrimary)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(DSTypography.cardCaption)
                        .foregroundColor(DSColors.textSecondary)
                }
            }

            Spacer()

            // LAYER 4: Expand/collapse chevron (right side)
            if canExpand, let onToggleExpand = onToggleExpand {
                Button(action: onToggleExpand) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(DSColors.textSecondary)
                }
                .accessibilityLabel(isExpanded ? "Collapse card" : "Expand card")
            }

            // LAYER 3: Eye-slash dismiss button (right side)
            if canDismiss, let onDismiss = onDismiss {
                Button(action: onDismiss) {
                    Image(systemName: "eye.slash")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(DSColors.textSecondary)
                }
                .accessibilityLabel("Hide \(title)")
            }
        }
        .padding(.bottom, DSSpacing.headerBottomSpacing)
    }
}

// MARK: - Preview

#Preview("Header with Dismiss Only") {
    ZStack {
        DSColors.screenBackground
            .ignoresSafeArea()

        VStack(spacing: 20) {
            DSCardHeader(
                title: "Current Weight",
                onDismiss: { print("Dismiss tapped") }
            )
            .padding()
            .background(DSColors.cardBackground)
            .cornerRadius(16)
            .padding(.horizontal, 20)

            DSCardHeader(
                title: "Milestone Card",
                subtitle: "6 of 10 completed",
                onDismiss: { print("Dismiss tapped") }
            )
            .padding()
            .background(DSColors.cardBackground)
            .cornerRadius(16)
            .padding(.horizontal, 20)
        }
    }
}

#Preview("Header with All Controls - Layer 5") {
    ZStack {
        DSColors.screenBackground
            .ignoresSafeArea()

        DSCardHeader(
            title: "Current Weight",
            subtitle: "Last updated today",
            onDismiss: { print("Dismiss tapped") },
            onToggleExpand: { print("Toggle expand tapped") },
            isExpanded: true,
            canDismiss: true,
            canExpand: true,
            canReorder: true
        )
        .padding()
        .background(DSColors.cardBackground)
        .cornerRadius(16)
        .padding(.horizontal, 20)
    }
}
