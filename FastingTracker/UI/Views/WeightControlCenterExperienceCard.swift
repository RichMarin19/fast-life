import SwiftUI

/// Manage My Experience card providing opt-out controls.
struct WeightControlCenterExperienceCard: View {
    @ObservedObject var viewModel: WeightControlCenterViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.cardPadding) {
            Text("Control which tips, nudges, and summaries you see (Opt-outs live here).")
                .font(DSTypography.iconButton)
                .foregroundColor(Theme.ColorToken.textSecondaryOnDark)
                .fixedSize(horizontal: false, vertical: true)

            Divider()
                .background(Theme.ColorToken.dividerOnDark)

            trackerCardsToggle()

            Divider()
                .background(Theme.ColorToken.dividerOnDark)

            categoryToggle(
                isOn: Binding(
                    get: { !viewModel.optOutEducationalInsights },
                    set: { viewModel.optOutEducationalInsights = !$0; viewModel.saveExperienceOptOuts() }
                ),
                title: "Educational Insights",
                description: "Learn about weight tracking science and best practices",
                category: .educationalInsights
            )

            Divider()
                .background(Theme.ColorToken.dividerOnDark)

            categoryToggle(
                isOn: Binding(
                    get: { !viewModel.optOutBehavioralNudges },
                    set: { viewModel.optOutBehavioralNudges = !$0; viewModel.saveExperienceOptOuts() }
                ),
                title: "Behavioral Nudges",
                description: "Gentle reminders to log weight and build streaks",
                category: .behavioralNudges
            )

            Divider()
                .background(Theme.ColorToken.dividerOnDark)

            categoryToggle(
                isOn: Binding(
                    get: { !viewModel.optOutMotivationalMessages },
                    set: { viewModel.optOutMotivationalMessages = !$0; viewModel.saveExperienceOptOuts() }
                ),
                title: "Motivational Messages",
                description: "Encouragement when you hit milestones or new lows",
                category: .motivationalMessages
            )

            Divider()
                .background(Theme.ColorToken.dividerOnDark)

            progressStoryCardsToggle()

            if viewModel.shouldShowRestoreButton {
                Divider()
                    .background(Theme.ColorToken.dividerOnDark)

                Button(action: { viewModel.showingRestoreAllAlert = true }) {
                    HStack(spacing: DSSpacing.cardSmallSpacing) {
                        Image(systemName: "arrow.clockwise")
                            .font(DSTypography.cardTitle)
                        Text("Restore All")
                            .font(DSTypography.cardTitle)
                    }
                    .foregroundColor(Theme.ColorToken.textPrimaryOnDark)
                    .frame(maxWidth: .infinity)
                    .padding(DSSpacing.cardElementSpacing)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Theme.ColorToken.accentGold.opacity(0.3))
                    )
                }
            }
        }
    }

    @ViewBuilder
    private func trackerCardsToggle() -> some View {
        VStack(alignment: .leading, spacing: DSSpacing.cardSmallSpacing) {
            Toggle(isOn: Binding(
                get: {
                    TrackerCardType.allCases
                        .filter { $0 != .history }
                        .allSatisfy { viewModel.cardManager.isCardVisible($0) }
                },
                set: { newValue in
                    TrackerCardType.allCases
                        .filter { $0 != .history }
                        .forEach { cardType in
                        if newValue {
                            viewModel.cardManager.showCard(cardType)
                        } else {
                            viewModel.cardManager.hideCard(cardType)
                        }
                        }
                    viewModel.optOutTrackerCards = !newValue
                    viewModel.saveExperienceOptOuts()
                }
            )) {
                VStack(alignment: .leading, spacing: DSSpacing.cardExtraSmallSpacing) {
                    Text("Weight Tracker Cards")
                        .font(DSTypography.listTitle)
                        .foregroundColor(Theme.ColorToken.textPrimaryOnDark)
                    Text("Manage which cards appear on your tracker")
                        .font(DSTypography.cardCaption)
                        .foregroundColor(Theme.ColorToken.textSecondaryOnDark)
                }
            }
            .tint(Theme.ColorToken.accentPrimary)

            let hiddenCards = TrackerCardType.allCases
                .filter { $0 != .history }
                .filter { cardType in
                    !viewModel.cardManager.isCardVisible(cardType)
                }

            if !hiddenCards.isEmpty {
                VStack(alignment: .leading, spacing: DSSpacing.cardSmallSpacing) {
                    Text("Hidden cards:")
                        .font(DSTypography.statLabel)
                        .foregroundColor(Theme.ColorToken.textSecondaryOnDark.opacity(0.7))
                        .padding(.leading, DSSpacing.cardPadding)
                        .padding(.top, DSSpacing.cardExtraSmallSpacing)

                    ForEach(hiddenCards) { cardType in
                        HStack(spacing: DSSpacing.cardSmallSpacing) {
                            Image(systemName: "eye.slash.fill")
                                .font(DSTypography.cardSubtitle)
                                .foregroundColor(Theme.ColorToken.stateWarning)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(cardType.displayName)
                                    .font(DSTypography.labelSecondary)
                                    .foregroundColor(Theme.ColorToken.textPrimaryOnDark)
                                Text(cardType.description)
                                    .font(DSTypography.pillLabel)
                                    .foregroundColor(Theme.ColorToken.textSecondaryOnDark.opacity(0.6))
                            }

                            Spacer()

                            Button("Restore") {
                                viewModel.restoreTrackerCard(cardType)
                            }
                            .font(DSTypography.statLabel)
                            .foregroundColor(Theme.ColorToken.accentPrimary)
                        }
                        .padding(.horizontal, DSSpacing.cardPadding)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Theme.ColorToken.textSecondaryOnDark.opacity(0.1))
                        )
                        .padding(.horizontal, DSSpacing.cardSmallSpacing)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func categoryToggle(isOn: Binding<Bool>, title: String, description: String, category: ContentCategory) -> some View {
        VStack(alignment: .leading, spacing: DSSpacing.cardSmallSpacing) {
            Toggle(isOn: isOn) {
                VStack(alignment: .leading, spacing: DSSpacing.cardExtraSmallSpacing) {
                    Text(title)
                        .font(DSTypography.listTitle)
                        .foregroundColor(Theme.ColorToken.textPrimaryOnDark)
                    Text(description)
                        .font(DSTypography.cardCaption)
                        .foregroundColor(Theme.ColorToken.textSecondaryOnDark)
                }
            }
            .tint(Theme.ColorToken.accentPrimary)

            let optedOutItems = viewModel.optOutManager.optedOutContentItems.filter { $0.category == category }
            if !optedOutItems.isEmpty {
                VStack(alignment: .leading, spacing: DSSpacing.cardSmallSpacing) {
                    Text("Individual opt-outs:")
                        .font(DSTypography.statLabel)
                        .foregroundColor(Theme.ColorToken.textSecondaryOnDark.opacity(0.7))
                        .padding(.leading, DSSpacing.cardPadding)
                        .padding(.top, DSSpacing.cardExtraSmallSpacing)

                    ForEach(Array(optedOutItems.enumerated()), id: \.element.id) { _, item in
                        let isHighlighted = viewModel.highlightedItemID == item.id

                        HStack(spacing: DSSpacing.cardSmallSpacing) {
                            Image(systemName: "minus.circle.fill")
                                .font(DSTypography.cardSubtitle)
                                .foregroundColor(Theme.ColorToken.stateWarning)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.displayText)
                                    .font(DSTypography.labelSecondary)
                                    .foregroundColor(Theme.ColorToken.textPrimaryOnDark)
                                Text("Opted out \(item.timestamp.formatted(date: .abbreviated, time: .omitted))")
                                    .font(DSTypography.pillLabel)
                                    .foregroundColor(Theme.ColorToken.textSecondaryOnDark.opacity(0.6))
                            }

                            Spacer()

                            Button("Restore") {
                                viewModel.optOutManager.optInContent(id: item.id)
                            }
                            .font(DSTypography.statLabel)
                            .foregroundColor(Theme.ColorToken.accentPrimary)
                        }
                        .padding(.horizontal, DSSpacing.cardPadding)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Theme.ColorToken.textSecondaryOnDark.opacity(0.1))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Theme.ColorToken.accentGold, lineWidth: isHighlighted ? 2 : 0)
                                .opacity(isHighlighted ? 1 : 0)
                        )
                        .shadow(
                            color: isHighlighted ? Theme.ColorToken.accentGold.opacity(0.3) : .clear,
                            radius: isHighlighted ? 8 : 0,
                            x: 0,
                            y: 0
                        )
                        .padding(.horizontal, DSSpacing.cardSmallSpacing)
                        .id(item.id)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func progressStoryCardsToggle() -> some View {
        VStack(alignment: .leading, spacing: DSSpacing.cardSmallSpacing) {
            Toggle(isOn: Binding(
                get: { viewModel.areAllProgressStoryCardsVisible },
                set: { newValue in viewModel.setProgressStoryExperienceVisible(newValue) }
            )) {
                VStack(alignment: .leading, spacing: DSSpacing.cardExtraSmallSpacing) {
                    Text("Your Progress Journey")
                        .font(DSTypography.listTitle)
                        .foregroundColor(Theme.ColorToken.textPrimaryOnDark)
                    Text("Weekly recaps showing trends and wins")
                        .font(DSTypography.cardCaption)
                        .foregroundColor(Theme.ColorToken.textSecondaryOnDark)
                }
            }
            .tint(Theme.ColorToken.accentPrimary)

            let hiddenCards = ProgressStoryCardType.allCases.filter { cardType in
                !viewModel.progressStoryCardManager.isCardVisible(cardType)
            }

            if !hiddenCards.isEmpty {
                VStack(alignment: .leading, spacing: DSSpacing.cardSmallSpacing) {
                    Text("Hidden cards:")
                        .font(DSTypography.statLabel)
                        .foregroundColor(Theme.ColorToken.textSecondaryOnDark.opacity(0.7))
                        .padding(.leading, DSSpacing.cardPadding)
                        .padding(.top, DSSpacing.cardExtraSmallSpacing)

                    ForEach(hiddenCards) { cardType in
                        HStack(spacing: DSSpacing.cardSmallSpacing) {
                            Image(systemName: "eye.slash.fill")
                                .font(DSTypography.cardSubtitle)
                                .foregroundColor(Theme.ColorToken.stateWarning)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(cardType.displayName)
                                    .font(DSTypography.labelSecondary)
                                    .foregroundColor(Theme.ColorToken.textPrimaryOnDark)
                                Text(cardType.description)
                                    .font(DSTypography.pillLabel)
                                    .foregroundColor(Theme.ColorToken.textSecondaryOnDark.opacity(0.6))
                            }

                            Spacer()

                            Button("Restore") {
                                viewModel.restoreProgressStoryCard(cardType)
                            }
                            .font(DSTypography.statLabel)
                            .foregroundColor(Theme.ColorToken.accentPrimary)
                        }
                        .padding(.horizontal, DSSpacing.cardPadding)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Theme.ColorToken.textSecondaryOnDark.opacity(0.1))
                        )
                        .padding(.horizontal, DSSpacing.cardSmallSpacing)
                    }
                }
            }
        }
    }
}
