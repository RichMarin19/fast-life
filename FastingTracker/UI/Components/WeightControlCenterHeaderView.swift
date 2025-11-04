import SwiftUI

// MARK: - Weight Control Center Gradient Background

/// Shared gradient background for the Weight Control Center.
/// Mirrors the presentation used across Weight Tracker surfaces so the visual brand stays consistent.
struct WeightControlCenterGradientBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                Theme.ColorToken.bgDeepStart,
                Theme.ColorToken.bgDeepMid
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}

// MARK: - Weight Control Center Header

/// Extracted header for the Weight Control Center.
/// Keeps the title, supporting copy, and Done action in a reusable component so the main view stays slim.
struct WeightControlCenterHeaderView: View {
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: DSSpacing.cardExtraSmallSpacing) {
            headerRow()
            instructionStack()
        }
    }

    @ViewBuilder
    private func headerRow() -> some View {
        HStack {
            Spacer()

            Text("Control Center")
                .font(DSTypography.screenTitle)
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Theme.ColorToken.accentCyan,
                            Theme.ColorToken.accentLightBlue
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )

            Spacer()

            Button(action: onDone) {
                Text("Done")
                    .font(DSTypography.buttonPrimary)
                    .foregroundColor(Theme.ColorToken.accentCyan)
                    .fontWeight(.semibold)
            }
            .accessibilityIdentifier("weightControlCenter.doneButton")
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, DSSpacing.cardSectionSpacing)
        .padding(.top, DSSpacing.cardSmallSpacing)
    }

    @ViewBuilder
    private func instructionStack() -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Customize your Weight Tracker experience.")
                .font(DSTypography.subtitleLarge)
                .foregroundColor(Theme.ColorToken.textSecondary)

            Text("Drag cards to reorder.")
                .font(DSTypography.subtitleEmphasized)
                .foregroundColor(Theme.ColorToken.textSecondary.opacity(0.8))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, DSSpacing.cardSectionSpacing)
        .padding(.bottom, DSSpacing.cardElementSpacing)
    }
}

#Preview("Weight Control Center Header") {
    ZStack {
        WeightControlCenterGradientBackground()

        WeightControlCenterHeaderView(onDone: {})
    }
}
