import SwiftUI

struct ProgressStoryContentIDs {
    let trendSnapshot: String
    let trendSnapshotLegacyIDs: [String]
    let banner: String
    let reflection: String
    let recap: String
    let didYouKnow: String
}

struct TrendSnapshotMetricContext: Identifiable {
    let id: String
    let title: String
    let valueText: String
    let unitText: String
    let tagText: String
    let tagTextColor: Color
    let tagBackgroundColor: Color
    let iconName: String
    let iconColor: Color
    let accessibilityLabel: String
}

struct ProgressStoryCardContext {
    let trendSnapshotMetrics: [TrendSnapshotMetricContext]
    let bannerText: String
    let bannerAccent: Color
    let didYouKnowText: String
    let reflectionPrompt: String
}

struct ProgressStoryCardStack: View {
    let visibleCards: [ProgressStoryCardType]
    let context: ProgressStoryCardContext
    let isAnimating: Bool
    @Binding private var draggedCard: ProgressStoryCardType?
    let reflectionTap: () -> Void
    let onHideCard: (ProgressStoryCardType) -> Void
    let onReorder: (ProgressStoryCardType, ProgressStoryCardType) -> Void

    init(visibleCards: [ProgressStoryCardType],
         context: ProgressStoryCardContext,
         isAnimating: Bool,
         draggedCard: Binding<ProgressStoryCardType?>,
         reflectionTap: @escaping () -> Void,
         onHideCard: @escaping (ProgressStoryCardType) -> Void,
         onReorder: @escaping (ProgressStoryCardType, ProgressStoryCardType) -> Void) {
        self.visibleCards = visibleCards
        self.context = context
        self.isAnimating = isAnimating
        _draggedCard = draggedCard
        self.reflectionTap = reflectionTap
        self.onHideCard = onHideCard
        self.onReorder = onReorder
    }

    var body: some View {
        ForEach(Array(visibleCards.enumerated()), id: \.element) { index, cardType in
            let moveEarlier: (() -> Void)? = index > 0 ? {
                let destination = visibleCards[index - 1]
                onReorder(cardType, destination)
            } : nil
            let moveLater: (() -> Void)? = index < visibleCards.count - 1 ? {
                let destination = visibleCards[index + 1]
                onReorder(cardType, destination)
            } : nil

            ProgressStoryReorderableCard(
                cardType: cardType,
                draggedCard: $draggedCard,
                isAnimating: isAnimating,
                onReorder: onReorder,
                moveEarlier: moveEarlier,
                moveLater: moveLater
            ) {
                cardContent(for: cardType)
            }
        }
    }

    // MARK: - Private

    @ViewBuilder
    private func cardContent(for cardType: ProgressStoryCardType) -> some View {
        switch cardType {
        case .trendSnapshot:
            TrendSnapshotCard(
                metrics: context.trendSnapshotMetrics,
                surfaceStyle: cardType.surfaceStyle ?? .ice,
                onHide: { onHideCard(.trendSnapshot) }
            )

        case .banner:
            ProgressBanner(
                text: context.bannerText,
                accent: context.bannerAccent,
                onHide: { onHideCard(.banner) }
            )

        case .reflection:
            ReflectionNudge(
                text: context.reflectionPrompt,
                onHide: { onHideCard(.reflection) },
                onTap: reflectionTap
            )

        case .didYouKnow:
            DidYouKnowBanner(
                text: context.didYouKnowText,
                onHide: { onHideCard(.didYouKnow) }
            )

        case .coachBar:
            EmptyView()
        }
    }
}

// MARK: - Reorderable Card Wrapper

private struct ProgressStoryReorderableCard<Content: View>: View {
    let cardType: ProgressStoryCardType
    @Binding var draggedCard: ProgressStoryCardType?
    let isAnimating: Bool
    let onReorder: (ProgressStoryCardType, ProgressStoryCardType) -> Void
    let moveEarlier: (() -> Void)?
    let moveLater: (() -> Void)?
    let content: Content

    init(
        cardType: ProgressStoryCardType,
        draggedCard: Binding<ProgressStoryCardType?>,
        isAnimating: Bool,
        onReorder: @escaping (ProgressStoryCardType, ProgressStoryCardType) -> Void,
        moveEarlier: (() -> Void)?,
        moveLater: (() -> Void)?,
        @ViewBuilder content: () -> Content
    ) {
        self.cardType = cardType
        _draggedCard = draggedCard
        self.isAnimating = isAnimating
        self.onReorder = onReorder
        self.moveEarlier = moveEarlier
        self.moveLater = moveLater
        self.content = content()
    }

    var body: some View {
        content
            .overlay(alignment: .leading) {
                dragHandle
                    .padding(.leading, DSSpacing.cardPadding * 0.6)
            }
            .contentShape(Rectangle())
            .onDrag {
                draggedCard = cardType
                return NSItemProvider(object: cardType.rawValue as NSString)
            }
            .onDrop(of: [.text], delegate: ProgressStoryCardDropDelegate(
                cardType: cardType,
                draggedCard: $draggedCard,
                onReorder: onReorder
            ))
            .opacity(isAnimating ? 1 : 0)
            .offset(y: isAnimating ? 0 : 20)
            .animation(.easeInOut(duration: 0.4), value: isAnimating)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(Text(cardType.displayName))
            .accessibilityHint(Text("progress_story_reorder_accessibility_hint"))
            .accessibilityAction(named: Text("progress_story_reorder_action_down")) {
                moveLater?()
            }
            .accessibilityAction(named: Text("progress_story_reorder_action_up")) {
                moveEarlier?()
            }
    }

    private var dragHandle: some View {
        Image(systemName: "line.3.horizontal")
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(Theme.ColorToken.textSecondary.opacity(0.65))
            .padding(.vertical, 6)
            .accessibilityHidden(true)
    }
}

// MARK: - Trend Snapshot Card

private struct TrendSnapshotCard: View {
    let metrics: [TrendSnapshotMetricContext]
    let surfaceStyle: WeightProgressStorySurfaceStyle
    let onHide: () -> Void

    var body: some View {
        WeightProgressStorySurfaceCard(style: surfaceStyle, onHide: onHide) {
            VStack(spacing: DSSpacing.cardSectionSpacing) {
                HStack {
                    Text("progress_story_trend_snapshot_title")
                        .font(DSTypography.cardTitle)
                        .dynamicTypeSize(.large ... .xxxLarge)
                        .foregroundColor(Theme.ColorToken.textPrimary)
                    Spacer()
                }

                HStack(alignment: .top, spacing: DSSpacing.cardSectionSpacing) {
                    ForEach(Array(metrics.enumerated()), id: \.element.id) { index, metric in
                        if index > 0 {
                            Divider()
                                .frame(height: 70)
                                .overlay(Theme.ColorToken.strokeLight.opacity(0.4))
                        }
                        TrendSnapshotMetricView(context: metric)
                    }
                }
            }
            .padding(.vertical, DSSpacing.cardSmallSpacing)
        }
    }
}

private struct TrendSnapshotMetricView: View {
    let context: TrendSnapshotMetricContext

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.cardExtraSmallSpacing) {
            HStack(spacing: DSSpacing.cardExtraSmallSpacing) {
                Image(systemName: context.iconName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(context.iconColor)
                Text(context.title)
                    .font(DSTypography.labelSecondary)
                    .foregroundColor(Theme.ColorToken.textSecondary)
            }

            HStack(alignment: .firstTextBaseline, spacing: DSSpacing.cardExtraSmallSpacing) {
                Text(context.valueText)
                    .font(DSTypography.statValueLarge)
                    .dynamicTypeSize(.large ... .xxxLarge)
                    .foregroundColor(Theme.ColorToken.textPrimary)
                if !context.unitText.isEmpty {
                    Text(context.unitText)
                        .font(DSTypography.cardSubtitle)
                        .dynamicTypeSize(.large ... .xxLarge)
                        .foregroundColor(Theme.ColorToken.textSecondary)
                }
            }

            Text(context.tagText)
                .font(DSTypography.pillLabel)
                .foregroundColor(context.tagTextColor)
                .padding(.horizontal, DSSpacing.cardExtraSmallSpacing)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(context.tagBackgroundColor)
                )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(context.accessibilityLabel))
    }
}
