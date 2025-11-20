import SwiftUI

/// About card providing summary metrics.
struct WeightControlCenterAboutCard: View {
    @ObservedObject var viewModel: WeightControlCenterViewModel

    var body: some View {
        let isExpanded = viewModel.expandedCards.contains("about")

        return VStack(spacing: 0) {
            HStack(spacing: DSSpacing.cardElementSpacing) {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(Theme.ColorToken.accentInfo)
                    .font(DSTypography.displayS)

                Text("About")
                    .font(DSTypography.displaySRounded)
                    .foregroundColor(Theme.ColorToken.textPrimaryOnDark)

                Spacer()

                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        if viewModel.expandedCards.contains("about") {
                            viewModel.expandedCards.remove("about")
                        } else {
                            viewModel.expandedCards.insert("about")
                        }
                        viewModel.saveExpandedCards()
                    }
                }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(DSTypography.cardTitle)
                        .foregroundColor(Theme.ColorToken.textSecondaryOnDark)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isExpanded ? "Collapse About section" : "Expand About section")
            }
            .padding(DSSpacing.cardPadding)
            .background(Theme.ColorToken.cardHeaderOnDark)

            if isExpanded {
                Divider()
                    .background(Theme.ColorToken.dividerOnDark)

                VStack(alignment: .leading, spacing: DSSpacing.cardElementSpacing) {
                    HStack {
                        Text("Total Entries")
                            .font(DSTypography.listTitle)
                            .foregroundColor(Theme.ColorToken.textSecondaryOnDark)
                        Spacer()
                        Text("\(viewModel.weightManager.weightEntries.count)")
                            .font(DSTypography.cardTitle)
                            .foregroundColor(Theme.ColorToken.textPrimaryOnDark)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Total entries \(viewModel.weightManager.weightEntries.count)")

                    if let oldest = viewModel.weightManager.weightEntries.sorted(by: { $0.date < $1.date }).first {
                        Divider()
                            .background(Theme.ColorToken.dividerOnDark)

                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Tracking Since")
                                    .font(DSTypography.listTitle)
                                    .foregroundColor(Theme.ColorToken.textSecondaryOnDark)
                                Spacer()
                                Text(oldest.date.formatted(date: .abbreviated, time: .omitted))
                                    .font(DSTypography.cardTitle)
                                    .foregroundColor(Theme.ColorToken.textPrimaryOnDark)
                            }
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("Tracking since \(oldest.date.formatted(date: .abbreviated, time: .omitted))")

                            HStack(spacing: 6) {
                                Image(systemName: "star.fill")
                                    .font(DSTypography.pillLabel)
                                    .foregroundColor(Theme.ColorToken.accentGold)
                                Text("You've logged \(viewModel.weightManager.weightEntries.count) entries since \(Calendar.current.component(.year, from: oldest.date))")
                                    .font(DSTypography.statLabel)
                                    .foregroundColor(Theme.ColorToken.textSecondaryOnDark)
                            }
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("Logged \(viewModel.weightManager.weightEntries.count) entries since \(Calendar.current.component(.year, from: oldest.date)))")
                            .padding(.top, DSSpacing.cardExtraSmallSpacing)
                        }
                    }
                }
                .padding(DSSpacing.cardPadding)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Theme.ColorToken.cardOnDark)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Theme.ColorToken.shadowCardOnDark, radius: 16, x: 0, y: 8)
    }
}
